import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: "#f0f7f4",
          100: "#dbeee4",
          200: "#b9ddca",
          300: "#8dc4a8",
          400: "#5ea682",
          500: "#3f8a66",
          600: "#2f6e51",
          700: "#275842",
          800: "#224737",
          900: "#1d3b2e",
        },
        accent: {
          500: "#c79443",
          600: "#a87a30",
        },
      },
      fontFamily: {
        sans: ["ui-sans-serif", "system-ui", "-apple-system", "Segoe UI", "Roboto", "sans-serif"],
      },
    },
  },
  plugins: [],
};

export default config;
