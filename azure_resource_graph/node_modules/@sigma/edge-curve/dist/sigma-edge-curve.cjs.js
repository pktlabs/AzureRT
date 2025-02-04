'use strict';

if (process.env.NODE_ENV === "production") {
  module.exports = require("./sigma-edge-curve.cjs.prod.js");
} else {
  module.exports = require("./sigma-edge-curve.cjs.dev.js");
}
