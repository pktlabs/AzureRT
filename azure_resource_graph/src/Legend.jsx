import React, { useState } from "react";

const RESOURCE_COLORS = {
  "AKS": "#17becf",
  "App Services": "#e377c2",
  "Automation Accounts": "#8c564b",
  "Federated Credentials": "#9edae5",
  "Key Vaults": "#9467bd",
  "UAManagedIdentities": "#ff7f0e",
  "Principals": "#d62728",
  "ResourceGroups": "#7f7f7f",
  "Storage Accounts": "#2ca02c",
  "Subscriptions": "#bcbd22",
  "SAManagedIdentities": "#98df8a",
  "VMs": "#1f77b4",
  "VM Scale Sets": "#aec7e8"  
};

const Legend = () => {
  const [isVisible, setIsVisible] = useState(false);

  return (
    <>
      <button className="legend-toggle" onClick={() => setIsVisible(!isVisible)}>
        {isVisible ? "Hide Legend" : "Show Legend"}
      </button>

      <div className={`legend-container ${isVisible ? "visible" : "hidden"}`}>
        <h3>Legend</h3>
        <ul>
          {Object.entries(RESOURCE_COLORS).map(([resource, color]) => (
            <li key={resource} className="legend-item">
              <span className="legend-color" style={{ backgroundColor: color }}></span>
              <span className="legend-text">{resource.split("/").pop()}</span>
            </li>
          ))}
        </ul>
      </div>
    </>
  );
};

export default Legend;
