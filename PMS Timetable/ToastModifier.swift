//
//  ToastModifier.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 29/4/2026.
//

import SwiftUI

struct Toast: Equatable {
	let message: String
	let isSuccess: Bool
}

struct ToastModifier: ViewModifier {
	@Binding var toast: Toast?
	@State private var task: Task<Void, Never>?

	func body(content: Content) -> some View {
		ZStack {
			content

			if let toast = toast {
				VStack {
					HStack(spacing: 12) {
						Image(systemName: toast.isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
							.foregroundStyle(toast.isSuccess ? .green : .red)

						Text(toast.message)
							.font(.subheadline)
							.lineLimit(2)

						Spacer()
					}
					.padding(12)
					.background(Color.gray.opacity(0.9))
					.cornerRadius(8)
					.padding()

					Spacer()
				}
				.transition(.move(edge: .top).combined(with: .opacity))
			}
		}
		.onChange(of: toast) { oldValue, newValue in
			if newValue != nil {
				task?.cancel()
				task = Task {
					try? await Task.sleep(nanoseconds: 3_000_000_000)
					if !Task.isCancelled {
						withAnimation {
							toast = nil
						}
					}
				}
			}
		}
	}
}

extension View {
	func toast(_ toast: Binding<Toast?>) -> some View {
		modifier(ToastModifier(toast: toast))
	}
}
