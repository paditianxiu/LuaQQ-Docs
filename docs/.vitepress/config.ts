import { defineConfig } from 'vitepress';

export default defineConfig({
  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }]
  ],


  locales: {
    // 默认语言：简体中文
    root: {
      label: '简体中文',
      lang: 'zh-CN',
      link: '/',
      title: 'LuaQQ',
      description: 'LuaQQ 官网',
      themeConfig: {
        logo: '/logo.png',
        nav: [
          { text: '下载', link: 'https://github.com/KuLiPai/LuaHook/releases/latest' }
        ],
        sidebar: [
          {
            items: [
              { text: '快速开始', link: '/quickstart' },
            ],
          },
          {
            text: '接口文档',
            items: [
              { text: '发送文字消息', link: '/sendTextMsg' },
              { text: '发送拍一拍', link: '/sendPai' },
              { text: '获取好友/群聊列表', link: '/getAllFriend' },

            ],
          },
          {
            text: '关于',
            items: [
              { text: 'LuaQQ团队', link: '/about/author-profile' },
            ],
          },
        ],
        socialLinks: [
          { icon: 'github', link: 'https://github.com/kulipai/luahook' },
          { icon: 'telegram', link: 'https://t.me/luaXposed' },
        ],
        footer: {
          message: 'Made with ❤️',
          copyright: 'Copyright © 2025-present <a href="https://github.com/paditianxiu">paditianxiu</a>'
        }
      }
    },
  },

});
