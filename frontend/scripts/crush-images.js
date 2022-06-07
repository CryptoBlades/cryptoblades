
const imagemin = require('imagemin');
const pngquant = require('imagemin-pngquant');

const init = async () => {
  await imagemin([
    'src/assets/background/*.png'
  ], {
    destination: 'src/assets/background',
    plugins: [
      pngquant({ 
        quality: [0.1, 0.2] 
      })
    ]
  });

  console.log('Done compressing images.');

};

init();
