module.exports = {
  plugins: [
    require('postcss-import')({ path: 'source/stylesheets' }),
    require('postcss-preset-env')({ stage: 4 }),
    require('postcss-simple-vars')(),
    require('postcss-custom-media')(),
    require('postcss-calc')({ preserve: false })
  ]
}
