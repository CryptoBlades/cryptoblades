<template>
  <div class="preloader">
  </div>
</template>

<style>


.preloader{
  position: absolute;
  margin: auto;
  top: 0;
  bottom: 0;
  right: 0;
  left: 0;
  height: 150px;
  width: 150px;
  border-radius: 50%;
  overflow: hidden;
  box-shadow: 0 0 5px #fff;
}

.preloader::before{
  content: "";
  background-image: linear-gradient(90deg, rgba(36, 39, 32, 1) 50%, #968332 100%);
  height: 150%;
  width: 150%;
  position: absolute;
  left: -25%;
  top: -25%;
  animation: clockwise-rotate 3s infinite linear;
}

.preloader::after{
  content: url('../../assets/cb_logo_preloader.png');
  height: 95%;
  width: 95%;
  position: absolute;
  background-color: rgba(36, 39, 32, 1);
  background-repeat: no-repeat;
  border-radius: 50%;
  top: 2.5%;
  left: 2.5%;
  display: grid;
  place-items: center;
}

</style>
