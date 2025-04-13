// agent.js - Wrapper untuk agent-js untuk ICP
const createAgent = async (identity = null, host = "https://ic0.app") => {
  const { HttpAgent, Actor } = window.ic.agent;
  
  // Buat agent dengan atau tanpa identitas
  const agent = new HttpAgent({ identity, host });
  
  // Opsional: fetch root key untuk local development
  if (host !== "https://ic0.app") {
    await agent.fetchRootKey();
  }
  
  return agent;
};

// Fungsi untuk membuat aktor yang berinteraksi dengan canister
const createActor = async (canisterId, idlFactory, options = {}) => {
  const { Actor } = window.ic.agent;
  const agent = await createAgent(options.identity, options.host);
  
  return Actor.createActor(idlFactory, {
    agent,
    canisterId,
    ...options,
  });
};

// Fungsi untuk membuat identitas dari kunci
const createIdentityFromKey = (privateKey) => {
  const { Ed25519KeyIdentity } = window.ic.identity;
  return Ed25519KeyIdentity.fromParsedJson(JSON.parse(privateKey));
};

// Fungsi untuk autentikasi dengan Internet Identity
const authenticateWithII = async (canisterId) => {
  const { AuthClient } = window.ic.auth;
  
  return new Promise((resolve, reject) => {
    AuthClient.create().then(authClient => {
      authClient.login({
        identityProvider: `https://${canisterId}.ic0.app`,
        onSuccess: () => {
          const identity = authClient.getIdentity();
          resolve(identity);
        },
        onError: (error) => {
          reject(error);
        }
      });
    });
  });
};

// Fungsi untuk meng-enkripsi dokumen
const encryptDocument = (document, publicKey) => {
  // Implementasi enkripsi client-side
  // Gunakan library enkripsi seperti tweetnacl atau libsodium
  // Ini hanya placeholder
  return {
    encryptedData: "encrypted_data_placeholder",
    nonce: "nonce_placeholder"
  };
};

// Fungsi untuk men-dekripsi dokumen
const decryptDocument = (encryptedData, nonce, privateKey) => {
  // Implementasi dekripsi client-side
  // Ini hanya placeholder
  return {
    decryptedData: "decrypted_data_placeholder"
  };
};

// Fungsi untuk generasi token verifikasi
const generateVerificationToken = async (actor, documentId, fields, expirySeconds) => {
  return await actor.generateVerificationToken(documentId, fields, expirySeconds);
};

// Fungsi untuk verifikasi token
const verifyToken = async (actor, token) => {
  return await actor.verifyToken(token);
};

// Export fungsi-fungsi ke global scope untuk diakses dari Flutter
window.icpAgent = {
  createAgent,
  createActor,
  createIdentityFromKey,
  authenticateWithII,
  encryptDocument,
  decryptDocument,
  generateVerificationToken,
  verifyToken
}; 