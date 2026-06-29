/** @type {import('tailwindcss').Config} */

const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Chakra Petch', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        'primary': '#ec2ca3', // Pink - Primary color
        'secondary': '#01dfec', // Blue - Secondary color
      },
      textShadow: {
        'sm': '0 0px 2px rgba(255, 255, 255, 0.1)',
        'DEFAULT': '0 0px 4px rgba(255, 255, 255, 0.1)',
        'md': '0 0px 0px rgba(255, 255, 255, 0.12)',
        'lg': '0 0px 16px rgba(255, 255, 255, 0.15)',
        'primary': '0 0px 4px rgba(236, 44, 163, 0.3)',
        'secondary': '0 0px 4px rgba(1, 223, 236, 0.3)',
        'white': '0 0px 4px rgba(255, 255, 255, 0.5)',
        'black': '0 0px 4px rgba(0, 0, 0, 0.5)',
        'gray': '0 0px 4px rgba(128, 128, 128, 0.5)',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require("tailwindcss-animate"),
    require('@tailwindcss/typography'),
    function({ addUtilities, theme, matchUtilities }) {
      // Add basic text shadow utilities
      const textShadows = theme('textShadow')
      const utilities = Object.entries(textShadows).map(([key, value]) => {
        return {
          [`.text-shadow${key === 'DEFAULT' ? '' : `-${key}`}`]: {
            textShadow: value,
          }
        }
      })
      addUtilities(utilities)
      
      // Add color-based text shadow utilities
      matchUtilities(
        {
          'text-shadow': (value) => ({
            textShadow: `0 0px 5px ${value}`,
          }),
        },
        { values: theme('colors') }
      )
    },
  ],
}
