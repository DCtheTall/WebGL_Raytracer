module.exports = {
  entry: './src/index.ts',
  output: { filename: './public/bundle.js' },
  resolve: {
    extensions: ['.ts', '.js', '.d.ts'],
  },
  module: {
    loaders: [
      {
        test: /\.ts$/,
        loader: 'ts-loader',
      },
    ],
  },
  plugins: [],
};
