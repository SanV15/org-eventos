/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,ts}"],
  theme: {
    extend: {},
  },
  plugins: [require("daisyui")],
  daisyui: {
    themes: ["corporate", "night"],
    darkTheme: "night",
    base: true,
    styled: true,
    utils: true,
  },
};
