//
//   SourceKind.swift
//   Shared
//
//   Created by Adon Omeri on 29/6/2026.
//

import Defaults

nonisolated enum SourceKind: String, Codable, Defaults.Serializable, Hashable {
	case accountOwner
	case authoredForThirdParty
}
