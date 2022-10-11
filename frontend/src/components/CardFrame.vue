<template>
  <svg class="frame-card" xmlns="http://www.w3.org/2000/svg" width="500.861" height="602.768" viewBox="0 0 410.861 602.768">
    <g id="enter-frame" transform="translate(-584.803 -285.44)">
      <g id="Group_7" data-name="Group 7" transform="translate(154 -23.94)">
        <g id="Group_2" data-name="Group 2" transform="translate(4.303 8.881)">
          <line id="Line_1" data-name="Line 1" y2="481.754" transform="translate(427.5 351.5)" fill="none" stroke="#edcd90" stroke-width="2"/>
          <line id="Line_2" data-name="Line 2" y2="481.754" transform="translate(836.362 351.5)" fill="none" stroke="#edcd90" stroke-width="2"/>
          <line id="Line_3" data-name="Line 3" x2="296" transform="translate(481.5 902.254)" fill="none" stroke="#edcd90" stroke-width="2"/>
          <line id="Line_4" data-name="Line 4" x2="296" transform="translate(481.5 301.5)" fill="none" stroke="#edcd90" stroke-width="2"/>
          <line id="Line_5" data-name="Line 5" y1="50" x2="54" transform="translate(427.5 301.5)" fill="none" stroke="#edcd90" stroke-width="2"/>
          <line id="Line_7" data-name="Line 7" x1="54" y1="69" transform="translate(427.5 833.254)" fill="none" stroke="#edcd90" stroke-width="2"/>
          <line id="Line_8" data-name="Line 8" y1="69.366" x2="59.165" transform="translate(777.197 833.254)" fill="none" stroke="#edcd90" stroke-width="2"/>
          <line id="Line_6" data-name="Line 6" x2="59.165" y2="49.846" transform="translate(777.197 301.654)" fill="none" stroke="#edcd90" stroke-width="2"/>
        </g>
        <g id="Group_3" data-name="Group 3">
          <line id="Line_9" data-name="Line 9" x2="27" y2="27" transform="translate(536.5 310.5)" fill="none" stroke="#edcd90" stroke-width="1"/>
          <line id="Line_10" data-name="Line 10" x1="27" y2="27" transform="translate(690.5 310.5)" fill="none" stroke="#edcd90" stroke-width="1"/>
          <line id="Line_11" data-name="Line 11" x2="127" transform="translate(563.5 337.5)" fill="none" stroke="#edcd90" stroke-width="1"/>
        </g>
        <g id="Group_4" data-name="Group 4" transform="translate(1263.234 1222) rotate(180)">
          <line id="Line_9-2" data-name="Line 9" x2="27" y2="27" transform="translate(536.5 310.5)" fill="none" stroke="#edcd90" stroke-width="1"/>
          <line id="Line_10-2" data-name="Line 10" x1="27" y2="27" transform="translate(690.5 310.5)" fill="none" stroke="#edcd90" stroke-width="1"/>
          <line id="Line_11-2" data-name="Line 11" x2="127" transform="translate(563.5 337.5)" fill="none" stroke="#edcd90" stroke-width="1"/>
        </g>
        <g id="Group_5" data-name="Group 5" transform="translate(1151.165 -16.06) rotate(90)">
          <line id="Line_9-3" data-name="Line 9" x2="27" y2="27" transform="translate(536.5 310.5)" fill="none" stroke="#edcd90" stroke-width="1"/>
          <line id="Line_10-3" data-name="Line 10" x1="27" y2="27" transform="translate(690.5 310.5)" fill="none" stroke="#edcd90" stroke-width="1"/>
          <line id="Line_11-3" data-name="Line 11" x2="127" transform="translate(563.5 337.5)" fill="none" stroke="#edcd90" stroke-width="1"/>
        </g>
        <g id="Group_6" data-name="Group 6" transform="translate(121.303 1237.94) rotate(-90)">
          <line id="Line_9-4" data-name="Line 9" x2="27" y2="27" transform="translate(536.5 310.5)" fill="none" stroke="#edcd90" stroke-width="1"/>
          <line id="Line_10-4" data-name="Line 10" x1="27" y2="27" transform="translate(690.5 310.5)" fill="none" stroke="#edcd90" stroke-width="1"/>
          <line id="Line_11-4" data-name="Line 11" x2="127" transform="translate(563.5 337.5)" fill="none" stroke="#edcd90" stroke-width="1"/>
        </g>
        <g id="Polygon_1" data-name="Polygon 1" transform="translate(478.5 586.5) rotate(90)" fill="none">
          <path d="M26,0,52,47H0Z" stroke="none"/>
          <path d="M 26 2.065845489501953 L 1.695999145507812 46 L 50.30400085449219 46 L 26 2.065845489501953 M 26 0 L 52 47 L 0 47 L 26 0 Z"
          stroke="none" fill="#edcd90"/>
        </g>
        <g id="Polygon_2" data-name="Polygon 2" transform="translate(793.665 638.5) rotate(-90)" fill="none">
          <path d="M26,0,52,47H0Z" stroke="none"/>
          <path d="M 26 2.065845489501953 L 1.695999145507812 46 L 50.30400085449219 46 L 26 2.065845489501953 M 26 0 L 52 47 L 0 47 L 26 0 Z"
          stroke="none" fill="#edcd90"/>
        </g>
        <g id="Polygon_3" data-name="Polygon 3" transform="translate(653.5 358) rotate(180)" fill="none">
          <path d="M26,0,52,47H0Z" stroke="none"/>
          <path d="M 26 2.065845489501953 L 1.695999145507812 46 L 50.30400085449219 46 L 26 2.065845489501953 M 26 0 L 52 47 L 0 47 L 26 0 Z"
          stroke="none" fill="#edcd90"/>
        </g>
      </g>
    </g>
  </svg>
</template>
<script>

export default{
  props: []
};
</script>
<style>
  .frame-card{
    height: 105%;
    width: 30%;
    margin-bottom: -1%;
    position: absolute;
  }

  @media all and (max-width: 600px) {
    .frame-card{
      height: 30%;
      width: 50vw;
      margin-bottom: 2.5%;
    }
  }

  .frame-card > g > g > g:nth-child(1) > line{
    stroke-dasharray: 500;
    stroke-dashoffset: 500;
  }

  a:hover > .frame-card > g > g > g:nth-child(1) > line{
    animation: animate-line 1s linear forwards;
  }

  a > .frame-card > g > g > g:nth-child(2) > line,
  a > .frame-card > g > g > g:nth-child(3) > line,
  a > .frame-card > g > g > g:nth-child(4) > line,
  a > .frame-card > g > g > g:nth-child(5) > line{
    stroke-dasharray: 500;
    stroke-dashoffset: 500;
  }

  a:hover > .frame-card > g > g > g:nth-child(2) > line,
  a:hover > .frame-card > g > g > g:nth-child(3) > line,
  a:hover > .frame-card > g > g > g:nth-child(4) > line,
  a:hover > .frame-card > g > g > g:nth-child(5) > line{
    animation: animate-line 1s linear forwards;
    animation-delay: 1s;
  }

  a > .frame-card > g > g > g:nth-child(6) > path,
  a > .frame-card > g > g > g:nth-child(7) > path,
  a > .frame-card > g > g > g:nth-child(8) > path{
    fill: transparent;
    stroke-dasharray: 500;
    stroke-dashoffset: 500;
    stroke-width: 1;
    stroke: #EDCD90;
  }

  a:hover > .frame-card > g > g > g:nth-child(6) > path,
  a:hover > .frame-card > g > g > g:nth-child(7) > path,
  a:hover > .frame-card > g > g > g:nth-child(8) > path{
    animation: animate-line 1s linear forwards;
    animation-delay: 1.5s;
  }


  @keyframes animate-line {
    0%{
      stroke-dashoffset: 500;
    }
    100%{
      stroke-dashoffset: 0;
    }
  }
</style>
