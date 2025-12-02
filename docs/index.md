---
layout: home

hero:
  name: LuaQQ
  text: Make QQ Great Again.
  tagline: 提供了一个后端环境，让你可以控制QQ。
  image:
    src: /logo.png
    alt: LuaQQ
    template: |
      <div class="image-container">
        <div class="image-wrapper">
          <div class="image-glow"></div>
          <img src="%s" alt="%s" class="image-src">
        </div>
      </div>
  actions:
    - theme: brand
      text: 快速开始
      link: /quickstart
    - theme: alt
      text: 在 GitHub 查看
      link: https://github.com/kulipai/luahook

features:
  - icon: 💻
    title: 强大的QQ控制能力
    details: 通过底层的 LuaHook 技术，提供对QQ应用流程和数据的深度访问和控制，实现强大的自动化和定制功能。
  - icon: ⚡️
    title: 零等待脚本加载
    details: 即刻加载、更新和调试你的 Lua 脚本，极大提升开发效率。
  - icon: ⚙️
    title: 稳定可靠的注入机制
    details: 结合实时 Hook 和持久化注入，确保您的插件在QQ的生命周期内持续稳定运行，且内存占用极低。
---
