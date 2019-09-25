module.exports = {
  plugins: [
    require('postcss-import')({ path: 'source/stylesheets' }),
    require('postcss-preset-env')({ stage: 4 }),
    require('postcss-custom-properties')({ preserve: false }),
    require('postcss-calc')({ preserve: false })
  ]
}
