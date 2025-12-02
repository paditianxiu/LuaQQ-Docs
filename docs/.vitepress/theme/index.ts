
import DefaultTheme from 'vitepress/theme'
import { h, defineComponent, nextTick, watch } from 'vue'
import { useRoute } from 'vitepress'
import confetti from 'canvas-confetti'
import "./custom.css"




var count = 200;
var defaults = {
  origin: { y: 0.7 }
};

function fire(particleRatio, opts) {
  confetti({
    ...defaults,
    ...opts,
    particleCount: Math.floor(count * particleRatio)
  });
}





function randomInRange(min, max) {
  return Math.random() * (max - min) + min;
}



export default {
  ...DefaultTheme,
  Layout: defineComponent({
    name: 'CustomLayout',
    setup() {
      const route = useRoute()


      /* 这是点击按钮🎉  */
      const setupConfettiButton = () => {
        if (typeof window === 'undefined') return // SSR 环境跳过
        const btn = document.getElementById('firework')
        if (btn && !btn.dataset.bound) {
          console.log('[confetti] binding firework button')
          btn.addEventListener('click', () => {
            confetti({
              angle: randomInRange(55, 125),
              spread: randomInRange(50, 70),
              particleCount: randomInRange(50, 100),
              origin: { y: 0.6 }
            })          
          })
          btn.dataset.bound = 'true'
        }
      }

      const setupScrollConfetti = () => {
        if (typeof window === 'undefined') return // SSR 环境跳过
        let triggered = false
        window.addEventListener('scroll', () => {
          const scrollTop = window.scrollY
          const viewportHeight = window.innerHeight
          const fullHeight = document.body.scrollHeight
          if (!triggered && scrollTop + viewportHeight >= fullHeight - 10) {
            triggered = true
            console.log('[confetti] scroll triggered')
            fire(0.25, {
              spread: 26,
              startVelocity: 55,
            });
            fire(0.2, {
              spread: 60,
            });
            fire(0.35, {
              spread: 100,
              decay: 0.91,
              scalar: 0.8
            });
            fire(0.1, {
              spread: 120,
              startVelocity: 25,
              decay: 0.92,
              scalar: 1.2
            });
            fire(0.1, {
              spread: 120,
              startVelocity: 45,
            })
          }
        })
      }

      watch(
        () => route.path,
        () => {
          console.log('[route] changed to', route.path)
          nextTick(() => {
            setupConfettiButton()
            /* 这是滑到页面底端显示🎉  */
            if (route.path === '/quickstart.html' || route.path === '/activate.html' || route.path === '/firstscript.html') {
              setupScrollConfetti()
            }
          })
        },
        { immediate: true }
      )

      return () => h(DefaultTheme.Layout)
    }
  })
}

