const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");

exports.processImageWithNano = onCall(
  {
    timeoutSeconds: 300,
    memory: "1GiB",
    // Bind the secret so Firebase will inject it into process.env.GEMINI
    // Create the secret with: firebase functions:secrets:set GEMINI
    // IMPORTANT: do NOT put the actual API key here. Use the secret's name.
    // Replace with the secret name you create in Secret Manager. Example:
    secrets: ["GEMINI"],
  },
  async (request) => {
    const data = request.data;
    const originalImageBase64 = data?.image;
    const userPrompt = data?.prompt;

    if (!originalImageBase64 || !userPrompt) {
      throw new HttpsError(
        "invalid-argument",
        'The function must be called with `image` and `prompt`.'
      );
    }

    // Basic size guard (adjust as needed). Avoid extremely large payloads.
    const MAX_BASE64_LENGTH = 6 * 1024 * 1024; // ~6MB characters
    if (originalImageBase64.length > MAX_BASE64_LENGTH) {
      throw new HttpsError(
        "invalid-argument",
        "Image is too large. Upload to Cloud Storage and pass a URL instead."
      );
    }

    // Strip data URI prefix if present
    const sanitizedBase64 = originalImageBase64.replace(/^data:image\/[a-zA-Z]+;base64,/, "");

    // Ensure API key is configured
    // Priority order (env vars supported):
    // 1) process.env.GEMINI (secret bound to function, per `secrets: ["GEMINI"]`)
    // 2) process.env.GEMINI_API_KEY (alternate common name)
    // 3) process.env.GEMINI_KEY
    let apiKey = process.env.GEMINI || process.env.GEMINI_API_KEY || process.env.GEMINI_KEY || null;

    // Note: don't attempt to call functions.config() because it's not available in v2.
    // If you previously used `firebase functions:config:set`, migrate those values to
    // environment variables or use the `params`/Secrets modules documented by Firebase.

    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "Missing API key. Set the secret `GEMINI` or an environment variable like GEMINI_API_KEY."
      );
    }

    try {
      // Initialize Google Generative AI
      const genAI = new GoogleGenerativeAI(apiKey);

      // Determine which model to use. Default to the image-capable Gemini model.
      // You can override with environment variable GENERATIVE_MODEL or GENERATIVE_MODEL_NAME.
      const MODEL_NAME = process.env.GENERATIVE_MODEL || process.env.GENERATIVE_MODEL_NAME || 'gemini-2.5-flash-image';
      console.info(`Using generative model: ${MODEL_NAME}`);
      const model = genAI.getGenerativeModel({ model: MODEL_NAME });

      // Prepare the prompt with image
      const prompt = [
        { text: userPrompt },
        {
          inlineData: {
            mimeType: "image/png", // Adjust if you support other formats
            data: sanitizedBase64,
          },
        },
      ];

      // Generate content
      const result = await model.generateContent(prompt);
      const response = await result.response;

      // Extract all generated images from the response
      const resultImages = [];
      let textResponse = null;

      // Helper: recursively collect inlineData objects anywhere in the response
      function collectInlineData(obj, out) {
        if (!obj || typeof obj !== 'object') return;
        if (obj.inlineData && obj.inlineData.data) {
          out.push({
            data: obj.inlineData.data,
            mimeType: obj.inlineData.mimeType || 'image/png',
          });
        }
        // also handle common alternative shapes
        if (Array.isArray(obj)) {
          for (const it of obj) collectInlineData(it, out);
          return;
        }
        for (const k of Object.keys(obj)) {
          try {
            collectInlineData(obj[k], out);
          } catch (e) {
            // ignore traversal errors
          }
        }
      }

      if (response.candidates && response.candidates[0]) {
        // Try the known candidates.content.parts path first
        try {
          const parts = response.candidates[0].content.parts;
          if (Array.isArray(parts)) {
            for (const part of parts) {
              if (part.inlineData && part.inlineData.data) {
                resultImages.push({
                  data: part.inlineData.data,
                  mimeType: part.inlineData.mimeType || 'image/png',
                });
              } else if (part.text) {
                textResponse = part.text;
              }
            }
          }
        } catch (e) {
          // ignore and fall back to a generic traversal
        }
      }

      // Fallback: recursively search the whole response for inlineData blocks
      if (resultImages.length === 0) {
        collectInlineData(response, resultImages);
      }

      if (resultImages.length === 0) {
        // Log the full response for debugging (do not leak secrets)
        try {
          console.error('No images generated in response. Full response:', JSON.stringify(response, null, 2));
        } catch (e) {
          console.error('No images generated and failed to stringify response:', e);
        }

        // Return a structured response so the client can show model text or a helpful message,
        // instead of treating this as an internal server error.
        return {
          images: [],
          text: textResponse,
          count: 0,
          warning: 'no_images_generated',
        };
      }

      // Return all images and optional text
      return {
        images: resultImages,
        text: textResponse,
        count: resultImages.length
      };
    } catch (err) {
      console.error("Gemini AI Generation Error:", err?.message || err, err);

      // Detect rate-limit / quota problems and return a clearer error
      const msg = err?.message || '';
      if (msg.includes('429') || /quota|too many requests|exceeded/i.test(msg)) {
        // Try to surface a retry hint if the library included headers or details
        let retryInfo = '';
        try {
          if (err?.response?.headers && err.response.headers['retry-after']) {
            retryInfo = ` Retry after ${err.response.headers['retry-after']}s.`;
          }
        } catch (e) {
          // ignore
        }
        throw new HttpsError('resource-exhausted', `AI rate limit or quota exceeded.${retryInfo}`);
      }

      throw new HttpsError(
        'internal',
        `AI processing failed: ${err?.message || 'Unknown error'}`
      );
    }
  });
