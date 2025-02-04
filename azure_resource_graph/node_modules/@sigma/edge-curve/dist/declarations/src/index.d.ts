import { EdgeProgramType } from "sigma/rendering";
export { default as createEdgeCurveProgram } from "./factory.js";
export { type CreateEdgeCurveProgramOptions } from "./utils.js";
export { indexParallelEdgesIndex, DEFAULT_EDGE_CURVATURE, DEFAULT_EDGE_CURVE_PROGRAM_OPTIONS, DEFAULT_INDEX_PARALLEL_EDGES_OPTIONS, } from "./utils.js";
export { createDrawCurvedEdgeLabel } from "./edge-labels.js";
declare const EdgeCurveProgram: EdgeProgramType;
export default EdgeCurveProgram;
export declare const EdgeCurvedArrowProgram: EdgeProgramType;
export declare const EdgeCurvedDoubleArrowProgram: EdgeProgramType;
