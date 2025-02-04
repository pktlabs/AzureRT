import { Attributes } from "graphology-types";
import { EdgeProgramType } from "sigma/rendering";
import { CreateEdgeCurveProgramOptions } from "./utils.js";
export default function createEdgeCurveProgram<N extends Attributes = Attributes, E extends Attributes = Attributes, G extends Attributes = Attributes>(inputOptions?: Partial<CreateEdgeCurveProgramOptions<N, E, G>>): EdgeProgramType<N, E, G>;
