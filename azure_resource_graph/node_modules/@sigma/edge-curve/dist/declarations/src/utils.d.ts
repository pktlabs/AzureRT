import Graph from "graphology";
import { Attributes } from "graphology-types";
import { EdgeLabelDrawingFunction } from "sigma/rendering";
export declare const DEFAULT_EDGE_CURVATURE = 0.25;
export type CreateEdgeCurveProgramOptions<N extends Attributes = Attributes, E extends Attributes = Attributes, G extends Attributes = Attributes> = {
    curvatureAttribute: string;
    defaultCurvature: number;
    arrowHead: null | {
        extremity: "target" | "source" | "both";
        lengthToThicknessRatio: number;
        widenessToThicknessRatio: number;
    };
    drawLabel?: EdgeLabelDrawingFunction<N, E, G> | undefined;
};
export declare const DEFAULT_EDGE_CURVE_PROGRAM_OPTIONS: CreateEdgeCurveProgramOptions;
/**
 * This function helps to identify parallel edges, to adjust their curvatures.
 */
export declare const DEFAULT_INDEX_PARALLEL_EDGES_OPTIONS: {
    edgeIndexAttribute: string;
    edgeMinIndexAttribute: string;
    edgeMaxIndexAttribute: string;
};
export declare function indexParallelEdgesIndex(graph: Graph, options?: Partial<typeof DEFAULT_INDEX_PARALLEL_EDGES_OPTIONS>): void;
