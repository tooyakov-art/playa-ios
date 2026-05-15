import SwiftUI

struct StarsStoreSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            starField.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    topBar
                        .padding(.horizontal, 22)
                        .padding(.top, 18)

                    VStack(spacing: 10) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 92, weight: .black))
                            .foregroundStyle(
                                LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .shadow(color: .yellow.opacity(0.35), radius: 22)

                        Text("Купить звёзды")
                            .font(.system(size: 34, weight: .black))
                            .foregroundColor(.white)

                        Text("Билеты в Playa оплачиваются звёздами.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 14) {
                        ForEach(StarPackage.telegramStyle) { package in
                            Button {
                                withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                                    appState.buyStars(package: package)
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 24, weight: .black))
                                        .foregroundStyle(
                                            LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                    Text("\(package.stars.formatted(.number.grouping(.automatic))) звёзд")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(package.priceText)
                                        .font(.system(size: 19, weight: .medium))
                                        .foregroundColor(.white.opacity(0.56))
                                }
                                .padding(.horizontal, 24)
                                .frame(height: 78)
                                .background(Color.white.opacity(0.14), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 22)

                    Button {
                    } label: {
                        HStack(spacing: 8) {
                            Text("Показать другие варианты")
                            Image(systemName: "chevron.down")
                        }
                        .font(.system(size: 19, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(Color.white.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            Button("Закрыть") { dismiss() }
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .frame(height: 54)
                .background(Color.white.opacity(0.12), in: Capsule())

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Баланс")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.yellow)
                    Text("\(appState.starBalance.formatted(.number.grouping(.automatic)))")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }

    private var starField: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let seed = Int(timeline.date.timeIntervalSinceReferenceDate * 2)
                for index in 0..<130 {
                    let x = CGFloat((index * 47 + seed * 11) % 1000) / 1000 * size.width
                    let y = CGFloat((index * 83 + seed * 7) % 700) / 700 * min(size.height, 360)
                    let radius = CGFloat(1 + (index % 4))
                    let rect = CGRect(x: x, y: y, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(.yellow.opacity(0.45 + Double(index % 4) * 0.12)))
                }
            }
        }
    }
}
