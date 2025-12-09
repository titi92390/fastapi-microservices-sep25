import axios from "axios";

// Configuration des ports NodePort (pour k3s local)
const DEFAULT_PORTS = {
  auth: "30081",
  users: "30082", 
  items: "30083",
};

// Fonction pour construire l'URL de base
const getBaseUrl = (service: keyof typeof DEFAULT_PORTS) => {
  if (typeof window === "undefined") return "";

  const { protocol, hostname } = window.location;
  const port = DEFAULT_PORTS[service];
  return `${protocol}//${hostname}:${port}/api/v1`;
};

// Créer les instances axios
export const apiAuth = axios.create();
export const apiUsers = axios.create();
export const apiItems = axios.create();

// Helper pour créer un interceptor
const createInterceptor = (service: keyof typeof DEFAULT_PORTS) => {
  return (config: any) => {
    if (config.url?.startsWith("/")) {
      config.url = getBaseUrl(service) + config.url;
    }
    
    // Attacher le token si présent
    if (typeof window !== "undefined") {
      const token = localStorage.getItem("token");
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    }
    
    return config;
  };
};

// Appliquer les interceptors
apiAuth.interceptors.request.use(createInterceptor("auth"));
apiUsers.interceptors.request.use(createInterceptor("users"));
apiItems.interceptors.request.use(createInterceptor("items"));