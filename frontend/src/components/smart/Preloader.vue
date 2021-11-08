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
  content: url('https://www.gitbook.com/cdn-cgi/image/width=40,height=40,fit=contain,dpr=1.25,format=auto/https%3A%2F%2Fcryptoblades.gitbook.io%2F~%2Ffiles%2Fv0%2Fb%2Fgitbook-28427.appspot.com%2Fo%2Fspaces%252F-MdGmpX4w7mgvE8wm1DQ%252Favatar-1625579572849.png%3Fgeneration%3D1625579573048975%26alt%3Dmedia');
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
