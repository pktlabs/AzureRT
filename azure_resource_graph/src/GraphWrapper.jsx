import React, { useEffect, useRef, useState } from "react";
import { SigmaContainer, useSigma } from "@react-sigma/core";
import forceAtlas2 from "graphology-layout-forceatlas2"; // New layout package
import { MultiGraph } from "graphology";
import { debounce } from "lodash";
import {
  indexParallelEdgesIndex,
  EdgeCurvedArrowProgram,
} from "@sigma/edge-curve";
import { EdgeArrowProgram } from "sigma/rendering";

const DEFAULT_EDGE_CURVATURE = 0.25;

function getCurvature(index, maxIndex) {
  if (maxIndex <= 0) throw new Error("Invalid maxIndex");
  if (index < 0) return -getCurvature(-index, maxIndex);
  const amplitude = 3.5;
  const maxCurvature =
    amplitude * (1 - Math.exp(-maxIndex / amplitude)) * DEFAULT_EDGE_CURVATURE;
  return (maxCurvature * index) / maxIndex;
}

const GraphComponent = ({ searchQuery, selectedCategory, graphData }) => {
  const sigma = useSigma();
  const [hoveredNode, setHoveredNode] = useState(null);
  const [frozenNode, setFrozenNode] = useState(null);
  const containerRef = useRef(null);

  // Setup graph and initial layout.
  useEffect(() => {
    if (!graphData) return;

    const graph = new MultiGraph({ multi: true });
    const { nodes, edges } = graphData;

    nodes.forEach((node) => {
      if (!graph.hasNode(node.id)) {
        // Optionally, add default positions:
        graph.addNode(node.id, {
          label: node.label,
          size: 5,
          color: node.color,
          resourceType: node.type,
          x: Math.random(),
          y: Math.random(),
        });
      }
    });

    edges.forEach((edge) => {
      graph.addEdge(edge.source, edge.target, {
        label: edge.label,
        color: edge.color,
        type: "arrow",
        size: 2,
      });
    });

    // Index parallel edges to assign curvature.
    indexParallelEdgesIndex(graph, {
      edgeIndexAttribute: "parallelIndex",
      edgeMinIndexAttribute: "parallelMinIndex",
      edgeMaxIndexAttribute: "parallelMaxIndex",
    });

    // Assign curvature to edges.
    graph.forEachEdge((edge, { parallelIndex, parallelMaxIndex }) => {
      const curvature =
        typeof parallelIndex === "number"
          ? getCurvature(parallelIndex, parallelMaxIndex)
          : 0;
      graph.mergeEdgeAttributes(edge, {
        type: curvature ? "curved" : "straight",
        curvature,
      });
    });

    // Use a force-directed layout instead of a random layout.
    forceAtlas2.assign(graph, { iterations: 100 });

    sigma.setGraph(graph);
    sigma.refresh();

    return () => graph.clear();
  }, [graphData, sigma]);

  // Control node/edge visibility based on search/hover/frozen states.
  useEffect(() => {
    if (!sigma || !graphData) return;

    const graph = sigma.getGraph();
    const debouncedRefresh = debounce(() => sigma.refresh(), 300);

    sigma.setSetting("nodeReducer", (node, data) => {
      const res = { ...data };

      if (frozenNode) {
        res.hidden =
          node !== frozenNode && !graph.areNeighbors(frozenNode, node);
        res.label =
          node === frozenNode || graph.areNeighbors(frozenNode, node)
            ? data.label
            : "";
      } else {
        if (
          searchQuery &&
          !data.label.toLowerCase().includes(searchQuery.toLowerCase())
        ) {
          res.hidden = true;
        } else if (selectedCategory && data.resourceType !== selectedCategory) {
          res.hidden = true;
        } else if (hoveredNode) {
          // Show node and its neighbors’ labels when hovered.
          res.hidden =
            hoveredNode !== node && !graph.areNeighbors(hoveredNode, node);
          res.label =
            hoveredNode === node || graph.areNeighbors(hoveredNode, node)
              ? data.label
              : "";
        } else {
          res.hidden = false;
        }
      }

      return res;
    });

    sigma.setSetting("edgeReducer", (edge, data) => {
      const res = { ...data };
      const [source, target] = graph.extremities(edge);

      if (frozenNode) {
        res.hidden = source !== frozenNode && target !== frozenNode;
      } else {
        if (
          (searchQuery &&
            (!graph
              .getNodeAttribute(source, "label")
              .toLowerCase()
              .includes(searchQuery.toLowerCase()) &&
              !graph
                .getNodeAttribute(target, "label")
                .toLowerCase()
                .includes(searchQuery.toLowerCase()))) ||
          (selectedCategory &&
            (graph.getNodeAttribute(source, "resourceType") !== selectedCategory &&
              graph.getNodeAttribute(target, "resourceType") !== selectedCategory))
        ) {
          res.hidden = true;
        } else if (hoveredNode && source !== hoveredNode && target !== hoveredNode) {
          res.hidden = true;
        } else {
          res.hidden = false;
        }
      }

      return res;
    });

    debouncedRefresh();
  }, [searchQuery, selectedCategory, hoveredNode, frozenNode, sigma, graphData]);

  // Event listeners for hover and click interactions.
  useEffect(() => {
    if (!sigma) return;

    const handleNodeHover = ({ node }) => {
      if (!frozenNode) setHoveredNode(node);
    };
    const handleNodeOut = () => {
      if (!frozenNode) setHoveredNode(null);
    };
    const handleNodeClick = ({ node }) => {
      setFrozenNode((prevFrozen) => (prevFrozen === node ? null : node));
    };

    sigma.on("enterNode", handleNodeHover);
    sigma.on("leaveNode", handleNodeOut);
    sigma.on("clickNode", handleNodeClick);

    return () => {
      sigma.off("enterNode", handleNodeHover);
      sigma.off("leaveNode", handleNodeOut);
      sigma.off("clickNode", handleNodeClick);
    };
  }, [sigma, frozenNode]);

  return <div ref={containerRef} />;
};

const GraphWrapper = ({ searchQuery, selectedCategory, graphData }) => {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
      {graphData ? (
        <SigmaContainer
          settings={{
            renderEdgeLabels: true,
            edgeProgramClasses: {
              straight: EdgeArrowProgram, // Straight edge rendering
              curved: EdgeCurvedArrowProgram, // Curved edge rendering
            },
          }}
        >
          <GraphComponent
            searchQuery={searchQuery}
            selectedCategory={selectedCategory}
            graphData={graphData}
          />
        </SigmaContainer>
      ) : (
        <p>Please upload a JSON file to visualize the graph.</p>
      )}
    </div>
  );
};

export default GraphWrapper;
