'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

var rendering = require('sigma/rendering');
var utils = require('sigma/utils');

function _toPrimitive(t, r) {
  if ("object" != typeof t || !t) return t;
  var e = t[Symbol.toPrimitive];
  if (void 0 !== e) {
    var i = e.call(t, r || "default");
    if ("object" != typeof i) return i;
    throw new TypeError("@@toPrimitive must return a primitive value.");
  }
  return ("string" === r ? String : Number)(t);
}

function _toPropertyKey(t) {
  var i = _toPrimitive(t, "string");
  return "symbol" == typeof i ? i : i + "";
}

function _defineProperty(e, r, t) {
  return (r = _toPropertyKey(r)) in e ? Object.defineProperty(e, r, {
    value: t,
    enumerable: !0,
    configurable: !0,
    writable: !0
  }) : e[r] = t, e;
}

function ownKeys(e, r) {
  var t = Object.keys(e);
  if (Object.getOwnPropertySymbols) {
    var o = Object.getOwnPropertySymbols(e);
    r && (o = o.filter(function (r) {
      return Object.getOwnPropertyDescriptor(e, r).enumerable;
    })), t.push.apply(t, o);
  }
  return t;
}
function _objectSpread2(e) {
  for (var r = 1; r < arguments.length; r++) {
    var t = null != arguments[r] ? arguments[r] : {};
    r % 2 ? ownKeys(Object(t), !0).forEach(function (r) {
      _defineProperty(e, r, t[r]);
    }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(e, Object.getOwnPropertyDescriptors(t)) : ownKeys(Object(t)).forEach(function (r) {
      Object.defineProperty(e, r, Object.getOwnPropertyDescriptor(t, r));
    });
  }
  return e;
}

function _classCallCheck(a, n) {
  if (!(a instanceof n)) throw new TypeError("Cannot call a class as a function");
}

function _defineProperties(e, r) {
  for (var t = 0; t < r.length; t++) {
    var o = r[t];
    o.enumerable = o.enumerable || !1, o.configurable = !0, "value" in o && (o.writable = !0), Object.defineProperty(e, _toPropertyKey(o.key), o);
  }
}
function _createClass(e, r, t) {
  return r && _defineProperties(e.prototype, r), t && _defineProperties(e, t), Object.defineProperty(e, "prototype", {
    writable: !1
  }), e;
}

function _getPrototypeOf(t) {
  return _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf.bind() : function (t) {
    return t.__proto__ || Object.getPrototypeOf(t);
  }, _getPrototypeOf(t);
}

function _isNativeReflectConstruct() {
  try {
    var t = !Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {}));
  } catch (t) {}
  return (_isNativeReflectConstruct = function () {
    return !!t;
  })();
}

function _assertThisInitialized(e) {
  if (void 0 === e) throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
  return e;
}

function _possibleConstructorReturn(t, e) {
  if (e && ("object" == typeof e || "function" == typeof e)) return e;
  if (void 0 !== e) throw new TypeError("Derived constructors may only return object or undefined");
  return _assertThisInitialized(t);
}

function _callSuper(t, o, e) {
  return o = _getPrototypeOf(o), _possibleConstructorReturn(t, _isNativeReflectConstruct() ? Reflect.construct(o, e || [], _getPrototypeOf(t).constructor) : o.apply(t, e));
}

function _setPrototypeOf(t, e) {
  return _setPrototypeOf = Object.setPrototypeOf ? Object.setPrototypeOf.bind() : function (t, e) {
    return t.__proto__ = e, t;
  }, _setPrototypeOf(t, e);
}

function _inherits(t, e) {
  if ("function" != typeof e && null !== e) throw new TypeError("Super expression must either be null or a function");
  t.prototype = Object.create(e && e.prototype, {
    constructor: {
      value: t,
      writable: !0,
      configurable: !0
    }
  }), Object.defineProperty(t, "prototype", {
    writable: !1
  }), e && _setPrototypeOf(t, e);
}

function _arrayLikeToArray(r, a) {
  (null == a || a > r.length) && (a = r.length);
  for (var e = 0, n = Array(a); e < a; e++) n[e] = r[e];
  return n;
}

function _arrayWithoutHoles(r) {
  if (Array.isArray(r)) return _arrayLikeToArray(r);
}

function _iterableToArray(r) {
  if ("undefined" != typeof Symbol && null != r[Symbol.iterator] || null != r["@@iterator"]) return Array.from(r);
}

function _unsupportedIterableToArray(r, a) {
  if (r) {
    if ("string" == typeof r) return _arrayLikeToArray(r, a);
    var t = {}.toString.call(r).slice(8, -1);
    return "Object" === t && r.constructor && (t = r.constructor.name), "Map" === t || "Set" === t ? Array.from(r) : "Arguments" === t || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(t) ? _arrayLikeToArray(r, a) : void 0;
  }
}

function _nonIterableSpread() {
  throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
}

function _toConsumableArray(r) {
  return _arrayWithoutHoles(r) || _iterableToArray(r) || _unsupportedIterableToArray(r) || _nonIterableSpread();
}

function getCurvePoint(t, p0, p1, p2) {
  var x = Math.pow(1 - t, 2) * p0.x + 2 * (1 - t) * t * p1.x + Math.pow(t, 2) * p2.x;
  var y = Math.pow(1 - t, 2) * p0.y + 2 * (1 - t) * t * p1.y + Math.pow(t, 2) * p2.y;
  return {
    x: x,
    y: y
  };
}
function getCurveLength(p0, p1, p2) {
  var steps = 20;
  var length = 0;
  var lastPoint = p0;
  for (var i = 0; i < steps; i++) {
    var point = getCurvePoint((i + 1) / steps, p0, p1, p2);
    length += Math.sqrt(Math.pow(lastPoint.x - point.x, 2) + Math.pow(lastPoint.y - point.y, 2));
    lastPoint = point;
  }
  return length;
}
function createDrawCurvedEdgeLabel(_ref) {
  var curvatureAttribute = _ref.curvatureAttribute,
    defaultCurvature = _ref.defaultCurvature,
    _ref$keepLabelUpright = _ref.keepLabelUpright,
    keepLabelUpright = _ref$keepLabelUpright === void 0 ? true : _ref$keepLabelUpright;
  return function (context, edgeData, sourceData, targetData, settings) {
    var size = settings.edgeLabelSize,
      curvature = edgeData[curvatureAttribute] || defaultCurvature,
      font = settings.edgeLabelFont,
      weight = settings.edgeLabelWeight,
      color = settings.edgeLabelColor.attribute ? edgeData[settings.edgeLabelColor.attribute] || settings.edgeLabelColor.color || "#000" : settings.edgeLabelColor.color;
    var label = edgeData.label;
    if (!label) return;
    context.fillStyle = color;
    context.font = "".concat(weight, " ").concat(size, "px ").concat(font);

    // Computing positions without considering nodes sizes:
    var ltr = !keepLabelUpright || sourceData.x < targetData.x;
    var sourceX = ltr ? sourceData.x : targetData.x;
    var sourceY = ltr ? sourceData.y : targetData.y;
    var targetX = ltr ? targetData.x : sourceData.x;
    var targetY = ltr ? targetData.y : sourceData.y;
    var centerX = (sourceX + targetX) / 2;
    var centerY = (sourceY + targetY) / 2;
    var diffX = targetX - sourceX;
    var diffY = targetY - sourceY;
    var diff = Math.sqrt(Math.pow(diffX, 2) + Math.pow(diffY, 2));
    // Anchor point:
    var orientation = ltr ? 1 : -1;
    var anchorX = centerX + diffY * curvature * orientation;
    var anchorY = centerY - diffX * curvature * orientation;

    // Adapt curve points to edge thickness:
    var offset = edgeData.size * 0.7 + 5;
    var sourceOffsetVector = {
      x: anchorY - sourceY,
      y: -(anchorX - sourceX)
    };
    var sourceOffsetVectorLength = Math.sqrt(Math.pow(sourceOffsetVector.x, 2) + Math.pow(sourceOffsetVector.y, 2));
    var targetOffsetVector = {
      x: targetY - anchorY,
      y: -(targetX - anchorX)
    };
    var targetOffsetVectorLength = Math.sqrt(Math.pow(targetOffsetVector.x, 2) + Math.pow(targetOffsetVector.y, 2));
    sourceX += offset * sourceOffsetVector.x / sourceOffsetVectorLength;
    sourceY += offset * sourceOffsetVector.y / sourceOffsetVectorLength;
    targetX += offset * targetOffsetVector.x / targetOffsetVectorLength;
    targetY += offset * targetOffsetVector.y / targetOffsetVectorLength;
    // For anchor, the vector is simpler, so it is inlined:
    anchorX += offset * diffY / diff;
    anchorY -= offset * diffX / diff;

    // Compute curve length:
    var anchorPoint = {
      x: anchorX,
      y: anchorY
    };
    var sourcePoint = {
      x: sourceX,
      y: sourceY
    };
    var targetPoint = {
      x: targetX,
      y: targetY
    };
    var curveLength = getCurveLength(sourcePoint, anchorPoint, targetPoint);
    if (curveLength < sourceData.size + targetData.size) return;

    // Handling ellipsis
    var textLength = context.measureText(label).width;
    var availableTextLength = curveLength - sourceData.size - targetData.size;
    if (textLength > availableTextLength) {
      var ellipsis = "…";
      label = label + ellipsis;
      textLength = context.measureText(label).width;
      while (textLength > availableTextLength && label.length > 1) {
        label = label.slice(0, -2) + ellipsis;
        textLength = context.measureText(label).width;
      }
      if (label.length < 4) return;
    }

    // Measure each character:
    var charactersLengthCache = {};
    for (var i = 0, length = label.length; i < length; i++) {
      var character = label[i];
      if (!charactersLengthCache[character]) {
        charactersLengthCache[character] = context.measureText(character).width * (1 + curvature * 0.35);
      }
    }

    // Draw each character:
    var t = 0.5 - textLength / curveLength / 2;
    for (var _i = 0, _length = label.length; _i < _length; _i++) {
      var _character = label[_i];
      var point = getCurvePoint(t, sourcePoint, anchorPoint, targetPoint);
      var tangentX = 2 * (1 - t) * (anchorX - sourceX) + 2 * t * (targetX - anchorX);
      var tangentY = 2 * (1 - t) * (anchorY - sourceY) + 2 * t * (targetY - anchorY);
      var angle = Math.atan2(tangentY, tangentX);
      context.save();
      context.translate(point.x, point.y);
      context.rotate(angle);

      // Dessiner le caractère
      context.fillText(_character, 0, 0);
      context.restore();
      t += charactersLengthCache[_character] / curveLength;
    }
  };
}

function getFragmentShader(_ref) {
  var arrowHead = _ref.arrowHead;
  var hasTargetArrowHead = (arrowHead === null || arrowHead === void 0 ? void 0 : arrowHead.extremity) === "target" || (arrowHead === null || arrowHead === void 0 ? void 0 : arrowHead.extremity) === "both";
  var hasSourceArrowHead = (arrowHead === null || arrowHead === void 0 ? void 0 : arrowHead.extremity) === "source" || (arrowHead === null || arrowHead === void 0 ? void 0 : arrowHead.extremity) === "both";

  // language=GLSL
  var SHADER = /*glsl*/"\nprecision highp float;\n\nvarying vec4 v_color;\nvarying float v_thickness;\nvarying float v_feather;\nvarying vec2 v_cpA;\nvarying vec2 v_cpB;\nvarying vec2 v_cpC;\n".concat(hasTargetArrowHead ? "\nvarying float v_targetSize;\nvarying vec2 v_targetPoint;" : "", "\n").concat(hasSourceArrowHead ? "\nvarying float v_sourceSize;\nvarying vec2 v_sourcePoint;" : "", "\n").concat(arrowHead ? "\nuniform float u_lengthToThicknessRatio;\nuniform float u_widenessToThicknessRatio;" : "", "\n\nfloat det(vec2 a, vec2 b) {\n  return a.x * b.y - b.x * a.y;\n}\n\nvec2 getDistanceVector(vec2 b0, vec2 b1, vec2 b2) {\n  float a = det(b0, b2), b = 2.0 * det(b1, b0), d = 2.0 * det(b2, b1);\n  float f = b * d - a * a;\n  vec2 d21 = b2 - b1, d10 = b1 - b0, d20 = b2 - b0;\n  vec2 gf = 2.0 * (b * d21 + d * d10 + a * d20);\n  gf = vec2(gf.y, -gf.x);\n  vec2 pp = -f * gf / dot(gf, gf);\n  vec2 d0p = b0 - pp;\n  float ap = det(d0p, d20), bp = 2.0 * det(d10, d0p);\n  float t = clamp((ap + bp) / (2.0 * a + b + d), 0.0, 1.0);\n  return mix(mix(b0, b1, t), mix(b1, b2, t), t);\n}\n\nfloat distToQuadraticBezierCurve(vec2 p, vec2 b0, vec2 b1, vec2 b2) {\n  return length(getDistanceVector(b0 - p, b1 - p, b2 - p));\n}\n\nconst vec4 transparent = vec4(0.0, 0.0, 0.0, 0.0);\n\nvoid main(void) {\n  float dist = distToQuadraticBezierCurve(gl_FragCoord.xy, v_cpA, v_cpB, v_cpC);\n  float thickness = v_thickness;\n").concat(hasTargetArrowHead ? "\n  float distToTarget = length(gl_FragCoord.xy - v_targetPoint);\n  float targetArrowLength = v_targetSize + thickness * u_lengthToThicknessRatio;\n  if (distToTarget < targetArrowLength) {\n    thickness = (distToTarget - v_targetSize) / (targetArrowLength - v_targetSize) * u_widenessToThicknessRatio * thickness;\n  }" : "", "\n").concat(hasSourceArrowHead ? "\n  float distToSource = length(gl_FragCoord.xy - v_sourcePoint);\n  float sourceArrowLength = v_sourceSize + thickness * u_lengthToThicknessRatio;\n  if (distToSource < sourceArrowLength) {\n    thickness = (distToSource - v_sourceSize) / (sourceArrowLength - v_sourceSize) * u_widenessToThicknessRatio * thickness;\n  }" : "", "\n\n  float halfThickness = thickness / 2.0;\n  if (dist < halfThickness) {\n    #ifdef PICKING_MODE\n    gl_FragColor = v_color;\n    #else\n    float t = smoothstep(\n      halfThickness - v_feather,\n      halfThickness,\n      dist\n    );\n\n    gl_FragColor = mix(v_color, transparent, t);\n    #endif\n  } else {\n    gl_FragColor = transparent;\n  }\n}\n");
  return SHADER;
}

function getVertexShader(_ref) {
  var arrowHead = _ref.arrowHead;
  var hasTargetArrowHead = (arrowHead === null || arrowHead === void 0 ? void 0 : arrowHead.extremity) === "target" || (arrowHead === null || arrowHead === void 0 ? void 0 : arrowHead.extremity) === "both";
  var hasSourceArrowHead = (arrowHead === null || arrowHead === void 0 ? void 0 : arrowHead.extremity) === "source" || (arrowHead === null || arrowHead === void 0 ? void 0 : arrowHead.extremity) === "both";

  // language=GLSL
  var SHADER = /*glsl*/"\nattribute vec4 a_id;\nattribute vec4 a_color;\nattribute float a_direction;\nattribute float a_thickness;\nattribute vec2 a_source;\nattribute vec2 a_target;\nattribute float a_current;\nattribute float a_curvature;\n".concat(hasTargetArrowHead ? "attribute float a_targetSize;\n" : "", "\n").concat(hasSourceArrowHead ? "attribute float a_sourceSize;\n" : "", "\n\nuniform mat3 u_matrix;\nuniform float u_sizeRatio;\nuniform float u_pixelRatio;\nuniform vec2 u_dimensions;\nuniform float u_minEdgeThickness;\nuniform float u_feather;\n\nvarying vec4 v_color;\nvarying float v_thickness;\nvarying float v_feather;\nvarying vec2 v_cpA;\nvarying vec2 v_cpB;\nvarying vec2 v_cpC;\n").concat(hasTargetArrowHead ? "\nvarying float v_targetSize;\nvarying vec2 v_targetPoint;" : "", "\n").concat(hasSourceArrowHead ? "\nvarying float v_sourceSize;\nvarying vec2 v_sourcePoint;" : "", "\n").concat(arrowHead ? "\nuniform float u_widenessToThicknessRatio;" : "", "\n\nconst float bias = 255.0 / 254.0;\nconst float epsilon = 0.7;\n\nvec2 clipspaceToViewport(vec2 pos, vec2 dimensions) {\n  return vec2(\n    (pos.x + 1.0) * dimensions.x / 2.0,\n    (pos.y + 1.0) * dimensions.y / 2.0\n  );\n}\n\nvec2 viewportToClipspace(vec2 pos, vec2 dimensions) {\n  return vec2(\n    pos.x / dimensions.x * 2.0 - 1.0,\n    pos.y / dimensions.y * 2.0 - 1.0\n  );\n}\n\nvoid main() {\n  float minThickness = u_minEdgeThickness;\n\n  // Selecting the correct position\n  // Branchless \"position = a_source if a_current == 1.0 else a_target\"\n  vec2 position = a_source * max(0.0, a_current) + a_target * max(0.0, 1.0 - a_current);\n  position = (u_matrix * vec3(position, 1)).xy;\n\n  vec2 source = (u_matrix * vec3(a_source, 1)).xy;\n  vec2 target = (u_matrix * vec3(a_target, 1)).xy;\n\n  vec2 viewportPosition = clipspaceToViewport(position, u_dimensions);\n  vec2 viewportSource = clipspaceToViewport(source, u_dimensions);\n  vec2 viewportTarget = clipspaceToViewport(target, u_dimensions);\n\n  vec2 delta = viewportTarget.xy - viewportSource.xy;\n  float len = length(delta);\n  vec2 normal = vec2(-delta.y, delta.x) * a_direction;\n  vec2 unitNormal = normal / len;\n  float boundingBoxThickness = len * a_curvature;\n\n  float curveThickness = max(minThickness, a_thickness / u_sizeRatio);\n  v_thickness = curveThickness * u_pixelRatio;\n  v_feather = u_feather;\n\n  v_cpA = viewportSource;\n  v_cpB = 0.5 * (viewportSource + viewportTarget) + unitNormal * a_direction * boundingBoxThickness;\n  v_cpC = viewportTarget;\n\n  vec2 viewportOffsetPosition = (\n    viewportPosition +\n    unitNormal * (boundingBoxThickness / 2.0 + sign(boundingBoxThickness) * (").concat(arrowHead ? "curveThickness * u_widenessToThicknessRatio" : "curveThickness", " + epsilon)) *\n    max(0.0, a_direction) // NOTE: cutting the bounding box in half to avoid overdraw\n  );\n\n  position = viewportToClipspace(viewportOffsetPosition, u_dimensions);\n  gl_Position = vec4(position, 0, 1);\n    \n").concat(hasTargetArrowHead ? "\n  v_targetSize = a_targetSize * u_pixelRatio / u_sizeRatio;\n  v_targetPoint = viewportTarget;\n" : "", "\n").concat(hasSourceArrowHead ? "\n  v_sourceSize = a_sourceSize * u_pixelRatio / u_sizeRatio;\n  v_sourcePoint = viewportSource;\n" : "", "\n\n  #ifdef PICKING_MODE\n  // For picking mode, we use the ID as the color:\n  v_color = a_id;\n  #else\n  // For normal mode, we use the color:\n  v_color = a_color;\n  #endif\n\n  v_color.a *= bias;\n}\n");
  return SHADER;
}

var DEFAULT_EDGE_CURVATURE = 0.25;
var DEFAULT_EDGE_CURVE_PROGRAM_OPTIONS = {
  arrowHead: null,
  curvatureAttribute: "curvature",
  defaultCurvature: DEFAULT_EDGE_CURVATURE
};

/**
 * This function helps to identify parallel edges, to adjust their curvatures.
 */
var DEFAULT_INDEX_PARALLEL_EDGES_OPTIONS = {
  edgeIndexAttribute: "parallelIndex",
  edgeMinIndexAttribute: "parallelMinIndex",
  edgeMaxIndexAttribute: "parallelMaxIndex"
};
function indexParallelEdgesIndex(graph, options) {
  var opts = _objectSpread2(_objectSpread2({}, DEFAULT_INDEX_PARALLEL_EDGES_OPTIONS), options || {});
  var nodeIDsMapping = {};
  var edgeDirectedIDsMapping = {};
  var edgeUndirectedIDsMapping = {};

  // Normalize IDs:
  var incr = 0;
  graph.forEachNode(function (node) {
    nodeIDsMapping[node] = ++incr + "";
  });
  graph.forEachEdge(function (edge, _attrs, source, target) {
    var sourceId = nodeIDsMapping[source];
    var targetId = nodeIDsMapping[target];
    var directedId = [sourceId, targetId].join("-");
    edgeDirectedIDsMapping[edge] = directedId;
    edgeUndirectedIDsMapping[directedId] = [sourceId, targetId].sort().join("-");
  });

  // Index edge unique IDs, only based on their extremities:
  var directedIndex = {};
  var undirectedIndex = {};
  graph.forEachEdge(function (edge) {
    var directedId = edgeDirectedIDsMapping[edge];
    var undirectedId = edgeUndirectedIDsMapping[directedId];
    directedIndex[directedId] = directedIndex[directedId] || [];
    directedIndex[directedId].push(edge);
    undirectedIndex[undirectedId] = undirectedIndex[undirectedId] || [];
    undirectedIndex[undirectedId].push(edge);
  });

  // Store index attributes:
  for (var directedId in directedIndex) {
    var edges = directedIndex[directedId];
    var directedCount = edges.length;
    var undirectedCount = undirectedIndex[edgeUndirectedIDsMapping[directedId]].length;

    // If the edge is alone, in both side:
    if (directedCount === 1 && undirectedCount === 1) {
      var edge = edges[0];
      graph.setEdgeAttribute(edge, opts.edgeIndexAttribute, null);
      graph.setEdgeAttribute(edge, opts.edgeMaxIndexAttribute, null);
    }

    // If the edge is alone, but there is at least one edge in the opposite direction:
    else if (directedCount === 1) {
      var _edge = edges[0];
      graph.setEdgeAttribute(_edge, opts.edgeIndexAttribute, 1);
      graph.setEdgeAttribute(_edge, opts.edgeMaxIndexAttribute, 1);
    }

    // If the edge is not alone, and all edges are in the same direction:
    else if (directedCount === undirectedCount) {
      var max = (directedCount - 1) / 2;
      var min = -max;
      for (var i = 0; i < directedCount; i++) {
        var _edge2 = edges[i];
        var edgeIndex = -(directedCount - 1) / 2 + i;
        graph.setEdgeAttribute(_edge2, opts.edgeIndexAttribute, edgeIndex);
        graph.setEdgeAttribute(_edge2, opts.edgeMinIndexAttribute, min);
        graph.setEdgeAttribute(_edge2, opts.edgeMaxIndexAttribute, max);
      }
    }

    // If the edge is not alone, and there are edges in both directions:
    else {
      for (var _i = 0; _i < directedCount; _i++) {
        var _edge3 = edges[_i];
        graph.setEdgeAttribute(_edge3, opts.edgeIndexAttribute, _i + 1);
        graph.setEdgeAttribute(_edge3, opts.edgeMaxIndexAttribute, directedCount);
      }
    }
  }
}

var _WebGLRenderingContex = WebGLRenderingContext,
  UNSIGNED_BYTE = _WebGLRenderingContex.UNSIGNED_BYTE,
  FLOAT = _WebGLRenderingContex.FLOAT;
function createEdgeCurveProgram(inputOptions) {
  var options = _objectSpread2(_objectSpread2({}, DEFAULT_EDGE_CURVE_PROGRAM_OPTIONS), inputOptions || {});
  var _ref = options,
    arrowHead = _ref.arrowHead,
    curvatureAttribute = _ref.curvatureAttribute,
    drawLabel = _ref.drawLabel;
  var hasTargetArrowHead = (arrowHead === null || arrowHead === void 0 ? void 0 : arrowHead.extremity) === "target" || (arrowHead === null || arrowHead === void 0 ? void 0 : arrowHead.extremity) === "both";
  var hasSourceArrowHead = (arrowHead === null || arrowHead === void 0 ? void 0 : arrowHead.extremity) === "source" || (arrowHead === null || arrowHead === void 0 ? void 0 : arrowHead.extremity) === "both";
  var UNIFORMS = ["u_matrix", "u_sizeRatio", "u_dimensions", "u_pixelRatio", "u_feather", "u_minEdgeThickness"].concat(_toConsumableArray(arrowHead ? ["u_lengthToThicknessRatio", "u_widenessToThicknessRatio"] : []));
  return /*#__PURE__*/function (_EdgeProgram) {
    _inherits(EdgeCurveProgram, _EdgeProgram);
    function EdgeCurveProgram() {
      var _this;
      _classCallCheck(this, EdgeCurveProgram);
      for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
        args[_key] = arguments[_key];
      }
      _this = _callSuper(this, EdgeCurveProgram, [].concat(args));
      _defineProperty(_assertThisInitialized(_this), "drawLabel", drawLabel || createDrawCurvedEdgeLabel(options));
      return _this;
    }
    _createClass(EdgeCurveProgram, [{
      key: "getDefinition",
      value: function getDefinition() {
        return {
          VERTICES: 6,
          VERTEX_SHADER_SOURCE: getVertexShader(options),
          FRAGMENT_SHADER_SOURCE: getFragmentShader(options),
          METHOD: WebGLRenderingContext.TRIANGLES,
          UNIFORMS: UNIFORMS,
          ATTRIBUTES: [{
            name: "a_source",
            size: 2,
            type: FLOAT
          }, {
            name: "a_target",
            size: 2,
            type: FLOAT
          }].concat(_toConsumableArray(hasTargetArrowHead ? [{
            name: "a_targetSize",
            size: 1,
            type: FLOAT
          }] : []), _toConsumableArray(hasSourceArrowHead ? [{
            name: "a_sourceSize",
            size: 1,
            type: FLOAT
          }] : []), [{
            name: "a_thickness",
            size: 1,
            type: FLOAT
          }, {
            name: "a_curvature",
            size: 1,
            type: FLOAT
          }, {
            name: "a_color",
            size: 4,
            type: UNSIGNED_BYTE,
            normalized: true
          }, {
            name: "a_id",
            size: 4,
            type: UNSIGNED_BYTE,
            normalized: true
          }]),
          CONSTANT_ATTRIBUTES: [{
            name: "a_current",
            size: 1,
            type: FLOAT
          },
          // TODO: could optimize to bool
          {
            name: "a_direction",
            size: 1,
            type: FLOAT
          } // TODO: could optimize to byte
          ],
          CONSTANT_DATA: [[0, 1], [0, -1], [1, 1], [0, -1], [1, 1], [1, -1]]
        };
      }
    }, {
      key: "processVisibleItem",
      value: function processVisibleItem(edgeIndex, startIndex, sourceData, targetData, data) {
        var _data;
        var thickness = data.size || 1;
        var x1 = sourceData.x;
        var y1 = sourceData.y;
        var x2 = targetData.x;
        var y2 = targetData.y;
        var color = utils.floatColor(data.color);
        var curvature = (_data = data[curvatureAttribute]) !== null && _data !== void 0 ? _data : DEFAULT_EDGE_CURVATURE;
        var array = this.array;

        // First point
        array[startIndex++] = x1;
        array[startIndex++] = y1;
        array[startIndex++] = x2;
        array[startIndex++] = y2;
        if (hasTargetArrowHead) array[startIndex++] = targetData.size;
        if (hasSourceArrowHead) array[startIndex++] = sourceData.size;
        array[startIndex++] = thickness;
        array[startIndex++] = curvature;
        array[startIndex++] = color;
        array[startIndex++] = edgeIndex;
      }
    }, {
      key: "setUniforms",
      value: function setUniforms(params, _ref2) {
        var gl = _ref2.gl,
          uniformLocations = _ref2.uniformLocations;
        var u_matrix = uniformLocations.u_matrix,
          u_pixelRatio = uniformLocations.u_pixelRatio,
          u_feather = uniformLocations.u_feather,
          u_sizeRatio = uniformLocations.u_sizeRatio,
          u_dimensions = uniformLocations.u_dimensions,
          u_minEdgeThickness = uniformLocations.u_minEdgeThickness;
        gl.uniformMatrix3fv(u_matrix, false, params.matrix);
        gl.uniform1f(u_pixelRatio, params.pixelRatio);
        gl.uniform1f(u_sizeRatio, params.sizeRatio);
        gl.uniform1f(u_feather, params.antiAliasingFeather);
        gl.uniform2f(u_dimensions, params.width * params.pixelRatio, params.height * params.pixelRatio);
        gl.uniform1f(u_minEdgeThickness, params.minEdgeThickness);
        if (arrowHead) {
          var u_lengthToThicknessRatio = uniformLocations.u_lengthToThicknessRatio,
            u_widenessToThicknessRatio = uniformLocations.u_widenessToThicknessRatio;
          gl.uniform1f(u_lengthToThicknessRatio, arrowHead.lengthToThicknessRatio);
          gl.uniform1f(u_widenessToThicknessRatio, arrowHead.widenessToThicknessRatio);
        }
      }
    }]);
    return EdgeCurveProgram;
  }(rendering.EdgeProgram);
}

var EdgeCurveProgram = createEdgeCurveProgram();
var EdgeCurvedArrowProgram = createEdgeCurveProgram({
  arrowHead: rendering.DEFAULT_EDGE_ARROW_HEAD_PROGRAM_OPTIONS
});
var EdgeCurvedDoubleArrowProgram = createEdgeCurveProgram({
  arrowHead: _objectSpread2(_objectSpread2({}, rendering.DEFAULT_EDGE_ARROW_HEAD_PROGRAM_OPTIONS), {}, {
    extremity: "both"
  })
});

exports.DEFAULT_EDGE_CURVATURE = DEFAULT_EDGE_CURVATURE;
exports.DEFAULT_EDGE_CURVE_PROGRAM_OPTIONS = DEFAULT_EDGE_CURVE_PROGRAM_OPTIONS;
exports.DEFAULT_INDEX_PARALLEL_EDGES_OPTIONS = DEFAULT_INDEX_PARALLEL_EDGES_OPTIONS;
exports.EdgeCurvedArrowProgram = EdgeCurvedArrowProgram;
exports.EdgeCurvedDoubleArrowProgram = EdgeCurvedDoubleArrowProgram;
exports.createDrawCurvedEdgeLabel = createDrawCurvedEdgeLabel;
exports.createEdgeCurveProgram = createEdgeCurveProgram;
exports["default"] = EdgeCurveProgram;
exports.indexParallelEdgesIndex = indexParallelEdgesIndex;
