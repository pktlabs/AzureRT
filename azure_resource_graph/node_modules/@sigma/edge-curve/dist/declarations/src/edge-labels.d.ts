import { Attributes } from "graphology-types";
import { EdgeLabelDrawingFunction } from "sigma/rendering";
import { CreateEdgeCurveProgramOptions } from "./utils.js";
export declare function createDrawCurvedEdgeLabel<N extends Attributes = Attributes, E extends Attributes = Attributes, G extends Attributes = Attributes>({ curvatureAttribute, defaultCurvature, keepLabelUpright, }: CreateEdgeCurveProgramOptions & {
    keepLabelUpright?: boolean;
}): EdgeLabelDrawingFunction<N, E, G>;
