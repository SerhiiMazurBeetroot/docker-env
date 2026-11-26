export function IconPlay({ className = "h-3.5 w-3.5" }) {
	return (
		<svg viewBox="0 0 16 16" className={className} fill="currentColor" aria-hidden>
			<path d="M5 3.2v9.6L13.2 8 5 3.2z" />
		</svg>
	);
}

export function IconRestart() {
	return (
		<svg viewBox="0 0 16 16" className="h-3.5 w-3.5" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" aria-hidden>
			<path d="M13.2 8A5.2 5.2 0 1 1 11.4 4" />
			<path d="M13.2 2.6v3.1H10" />
		</svg>
	);
}

export function IconRebuild() {
	return (
		<svg viewBox="0 0 16 16" className="h-3.5 w-3.5" fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden>
			<rect x="3" y="8.2" width="10" height="4.3" rx="1" />
			<rect x="5" y="3.5" width="6" height="3.8" rx="1" />
		</svg>
	);
}

export function IconStop({ className = "h-3.5 w-3.5" }) {
	return (
		<svg viewBox="0 0 16 16" className={className} fill="currentColor" aria-hidden>
			<rect x="4.2" y="4.2" width="7.6" height="7.6" rx="1.4" />
		</svg>
	);
}

export function IconCopy({ className = "h-3 w-3" }) {
	return (
		<svg viewBox="0 0 16 16" className={className} fill="none" stroke="currentColor" strokeWidth="1.5" aria-hidden>
			<rect x="5.2" y="5.2" width="7.4" height="7.4" rx="1.2" />
			<path d="M3.5 10.2V3.8A1.3 1.3 0 0 1 4.8 2.5h6.4" />
		</svg>
	);
}

export function IconCheck({ className = "h-3 w-3" }) {
	return (
		<svg viewBox="0 0 16 16" className={className} fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden>
			<path d="m3.5 8.2 3 3 6-6.4" />
		</svg>
	);
}

export function IconExternal({ className = "h-3 w-3" }) {
	return (
		<svg viewBox="0 0 16 16" className={className} fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden>
			<path d="M9.2 3.2h3.6v3.6" />
			<path d="M8.2 7.8 12.8 3.2" />
			<path d="M12.2 9.4v3.2A1.2 1.2 0 0 1 11 13.8H4.6A1.2 1.2 0 0 1 3.4 12.6V6.2A1.2 1.2 0 0 1 4.6 5h3.1" />
		</svg>
	);
}

export function IconSearch() {
	return (
		<svg viewBox="0 0 16 16" className="h-4 w-4 text-muted" fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden>
			<circle cx="7" cy="7" r="4.2" />
			<path d="m13.2 13.2-3-3" />
		</svg>
	);
}

export function IconClose({ className = "h-4 w-4" }) {
	return (
		<svg viewBox="0 0 16 16" className={className} fill="none" stroke="currentColor" strokeWidth="1.7" aria-hidden>
			<path d="m4 4 8 8M12 4 4 12" />
		</svg>
	);
}

export function IconExpand({ className = "h-2.5 w-3.5" }) {
	return (
		<svg viewBox="0 0 9 6" className={className} fill="currentColor" aria-hidden>
			<path fillRule="evenodd" d="M8 6c.412 0 .647-.47.4-.8L4.9.533a.5.5 0 0 0-.8 0L.6 5.2C.353 5.53.588 6 1 6h7Z" />
		</svg>
	);
}

export function IconCollapse({ className = "h-2.5 w-3.5" }) {
	return (
		<svg viewBox="0 0 9 6" className={className} fill="currentColor" aria-hidden>
			<path fillRule="evenodd" d="M8 0c.412 0 .647.47.4.8L4.9 5.467a.5.5 0 0 1-.8 0L.6.8C.353.47.588 0 1 0h7Z" />
		</svg>
	);
}

export function IconChevron({ className = "h-3 w-3" }) {
	return (
		<svg viewBox="0 0 16 16" className={className} fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden>
			<path d="M4 6.2 8 10.2 12 6.2" />
		</svg>
	);
}

export function IconMore({ className = "h-3.5 w-3.5" }) {
	return (
		<svg viewBox="0 0 16 16" className={className} fill="currentColor" aria-hidden>
			<circle cx="3.5" cy="8" r="1.35" />
			<circle cx="8" cy="8" r="1.35" />
			<circle cx="12.5" cy="8" r="1.35" />
		</svg>
	);
}

export function IconPlus({ className = "h-3.5 w-3.5" }) {
	return (
		<svg viewBox="0 0 16 16" className={className} fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden>
			<path d="M8 3.2v9.6M3.2 8h9.6" />
		</svg>
	);
}

export function IconInfo({ className = "h-3.5 w-3.5" }) {
	return (
		<svg viewBox="0 0 16 16" className={className} fill="none" stroke="currentColor" strokeWidth="1.5" aria-hidden>
			<circle cx="8" cy="8" r="5.8" />
			<path d="M8 7.2v3.6M8 5.2v.1" strokeLinecap="round" />
		</svg>
	);
}

export function IconWarn({ className = "h-3.5 w-3.5" }) {
	return (
		<svg viewBox="0 0 16 16" className={className} fill="none" stroke="currentColor" strokeWidth="1.5" aria-hidden>
			<path d="M7.1 2.6a1 1 0 0 1 1.8 0l5.3 9.6a1 1 0 0 1-.9 1.5H2.7a1 1 0 0 1-.9-1.5l5.3-9.6z" strokeLinejoin="round" />
			<path d="M8 6.2v3.2M8 11.4v.1" strokeLinecap="round" />
		</svg>
	);
}

export function IconTrash({ className = "h-3.5 w-3.5" }) {
	return (
		<svg viewBox="0 0 16 16" className={className} fill="none" stroke="currentColor" strokeWidth="1.5" aria-hidden>
			<path d="M3.5 4.5h9M6.2 4.5V3.4h3.6v1.1M5.2 6.2v6.2h5.6V6.2" />
		</svg>
	);
}

export function Spinner({ className = "h-4 w-4" }) {
	return (
		<svg className={`${className} animate-spin`} viewBox="0 0 16 16" fill="none" aria-hidden>
			<circle cx="8" cy="8" r="6" stroke="currentColor" strokeOpacity="0.2" strokeWidth="2" />
			<path d="M14 8a6 6 0 0 0-6-6" stroke="currentColor" strokeWidth="2" />
		</svg>
	);
}
