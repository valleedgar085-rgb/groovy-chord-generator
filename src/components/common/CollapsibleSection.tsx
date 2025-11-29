/**
 * Groovy Chord Generator
 * Collapsible Section Component
 * Version 2.4
 */

import { useState, type ReactNode } from 'react';

interface CollapsibleSectionProps {
  title: string;
  icon?: string;
  defaultExpanded?: boolean;
  children: ReactNode;
}

export function CollapsibleSection({
  title,
  icon,
  defaultExpanded = false,
  children,
}: CollapsibleSectionProps) {
  const [isExpanded, setIsExpanded] = useState(defaultExpanded);

  return (
    <div className={`collapsible-section ${isExpanded ? 'expanded' : ''}`}>
      <button
        className="collapsible-header"
        aria-expanded={isExpanded}
        onClick={() => setIsExpanded(!isExpanded)}
      >
        <span>
          {icon && `${icon} `}
          {title}
        </span>
        <span className="collapse-icon">▼</span>
      </button>
      <div className="collapsible-content">{children}</div>
    </div>
  );
}
