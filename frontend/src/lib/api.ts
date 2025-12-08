import axios from "axios";

// Extraire host et protocole SANS le port
const getBaseUrl = (port: string) => {
  if (typeof window === "undefined") return "";
  
  const { protocol, hostname } = window.location;
  return `${protocol}//${hostname}:${port}/api/v1`;
};

export const apiAuth = axios.create();
export const apiUsers = axios.create();
export const apiItems = axios.create();

// Interceptor Auth
apiAuth.interceptors.request.use((config) => {
  if (config.url?.startsWith("/")) {
    config.url = getBaseUrl("30081") + config.url;
  }
  const token = typeof window !== "undefined" ? localStorage.getItem("token") : null;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Interceptor Users
apiUsers.interceptors.request.use((config) => {
  if (config.url?.startsWith("/")) {
    config.url = getBaseUrl("30082") + config.url;
  }
  const token = typeof window !== "undefined" ? localStorage.getItem("token") : null;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Interceptor Items
apiItems.interceptors.request.use((config) => {
  if (config.url?.startsWith("/")) {
    config.url = getBaseUrl("30083") + config.url;
  }
  const token = typeof window !== "undefined" ? localStorage.getItem("token") : null;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});