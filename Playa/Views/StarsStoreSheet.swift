import SwiftUI

struct StarsStoreSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            PlayaBackground()
            starField.ignoresSafeArea().opacity(0.7)

            ScrollView {
                VStack(spacing: 24) {
                    topBar
                        .padding(.horizontal, 18)
                        .padding(.top, 12)

                    VStack(spacing: 14) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 76, weight: .black))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [PlayaStyle.lime, PlayaStyle.ember],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: PlayaStyle.ember.opacity(0.45), radius: 22)

                        Text("Демо-звёзды Playa")
                            .font(.playaDisplay(32, weight: .black))
                            .foregroundColor(.white)
                            .tracking(-0.4)

                        Text("Звёзды сейчас работают как демо-баланс для предпросмотра билетов. Реальные покупки отключены до StoreKit.")
                            .playaBody()
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 10) {
                        ForEach(StarPackage.telegramStyle) { package in
                            packageRow(package)
                        }
                    }
                    .padding(.horizontal, 18)

                    Button { } label: {
                        HStack(spacing: 8) {
                            Text("Покупки появятся после StoreKit")
                            Image(systemName: "lock.fill")
                        }
                    }
                    .buttonStyle(PlayaGhostButton())
                    .disabled(true)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 28)
                }
            }
        }
    }

    // MARK: - Pieces

    private var topBar: some View {
        HStack(alignment: .center) {
            Button {
                PlayaFeedback.selection()
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(PlayaIconButton(size: 42))

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(PlayaStyle.lime)
                Text(appState.starBalance.formatted(.number.grouping(.automatic)))
                    .font(.playaMono(15, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .frame(height: 42)
            .playaGlass(cornerRadius: 21)
        }
    }

    private func packageRow(_ package: StarPackage) -> some View {
        Button {
            PlayaFeedback.impact(.medium)
            withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                appState.buyStars(package: package)
            }
            ToastCenter.shared.success("Зачислено \(package.stars.formatted(.number.grouping(.automatic))) ★")
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "star.fill")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [PlayaStyle.lime, PlayaStyle.ember],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1))

                Text("\(package.stars.formatted(.number.grouping(.automatic))) демо-звёзд")
                    .font(.playaSans(17, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(package.priceText.uppercased())
                    .playaLabel(color: PlayaStyle.bone.opacity(0.85))
            }
            .padding(.horizontal, 18)
            .frame(height: 68)
            .playaPoster()
        }
        .buttonStyle(.plain)
    }

    private var starField: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let seed = Int(timeline.date.timeIntervalSinceReferenceDate * 2)
                for index in 0..<140 {
                    let x = CGFloat((index * 47 + seed * 11) % 1000) / 1000 * size.width
                    let y = CGFloat((index * 83 + seed * 7) % 700) / 700 * min(size.height, 360)
                    let radius = CGFloat(1 + (index % 4))
                    let rect = CGRect(x: x, y: y, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.35 + Double(index % 4) * 0.10)))
                }
            }
        }
    }
}
