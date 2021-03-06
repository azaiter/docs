# this is a normal CoffeeScript CommonJS module.
# so you can use strings interpolation, reuse variables, and everything

RPI_PRODUCTS = 'https://www.raspberrypi.org/products'
BB_PRODUCTS = 'https://beagleboard.org'

module.exports =
  raspberrypi:
    aplus: "#{RPI_PRODUCTS}/model-a-plus/"
    bplus: "#{RPI_PRODUCTS}/model-b-plus/"
  beaglebone:
    black: "#{BB_PRODUCTS}/black"
    green: "#{BB_PRODUCTS}/green"
  githubMain: 'https://github.com/balena-io'
  githubProjects: 'https://github.com/resin-io-projects'
  githubOS: 'https://github.com/resin-os'
  apiBase: process.env.API_BASE || 'https://api.balena-cloud.com/'
  mainSiteUrl: '/'
  dashboardUrl: process.env.DASHBOARD_SITE || 'https://dashboard.balena-cloud.com'
