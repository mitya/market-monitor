module.exports = {
  test: /\.(coffee|cjsx)(\.erb)?$/,
  use: [
    { loader: 'babel-loader' },
    { loader: 'coffee-loader' }
  ]
}
