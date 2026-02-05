//
//  AffirmationMagicView.swift
//  PelvicFloorApp
//
//  Авто-рандом карта: без выбора пользователем
//

import SwiftUI

struct AffirmationMagicView: View {
    let onClose: () -> Void

    private let affirmations: [String] = [

        // Тело и принятие
        "Моё тело знает, как восстанавливаться. Я позволяю ему делать свою работу.",
        "Я отношусь к своему телу с уважением, а не с требованиями.",
        "Моё тело — мой союзник, а не задача для исправления.",
        "Я слышу сигналы своего тела и отвечаю на них бережно.",
        "Мне не нужно бороться с собой, чтобы быть в порядке.",
        "Я выбираю заботу вместо контроля.",
        "Моё тело достойно любви уже сейчас.",
        "Я разрешаю себе быть в том темпе, который мне подходит.",
        "Я доверяю естественной мудрости своего тела.",
        "Моё тело — безопасное пространство для меня.",

        // Дыхание и спокойствие
        "Моё дыхание возвращает меня в настоящий момент.",
        "С каждым выдохом я отпускаю лишнее напряжение.",
        "Я могу замедлиться, и мир не рухнет.",
        "Я нахожу опору в простых вещах: дыхании, движении, тишине.",
        "Спокойствие доступно мне здесь и сейчас.",
        "Я выбираю мягкость в ответ на стресс.",
        "Моё дыхание — мой якорь.",
        "Я позволяю себе паузы без чувства вины.",
        "Я умею останавливаться и чувствовать.",
        "В тишине я нахожу ясность.",

        // Благодарность
        "Я благодарна своему телу за всё, что оно делает для меня каждый день.",
        "Я замечаю маленькие вещи, которые поддерживают меня.",
        "Мне есть за что поблагодарить этот день.",
        "Я ценю путь, который уже прошла.",
        "Я благодарю себя за заботу о себе.",
        "Я благодарна за способность чувствовать.",
        "Я замечаю, как жизнь поддерживает меня.",
        "Даже в сложных днях есть что-то ценное.",
        "Я благодарю себя за выбор быть внимательной к себе.",
        "Моя благодарность заземляет меня.",

        // Самоценность
        "Мне не нужно заслуживать право быть собой.",
        "Я достаточно хороша без доказательств.",
        "Моя ценность не зависит от продуктивности.",
        "Я имею право быть разной.",
        "Я не обязана соответствовать чужим ожиданиям.",
        "Моя ценность — внутренняя и стабильная.",
        "Я принимаю себя без условий.",
        "Мне не нужно сравнивать себя с другими.",
        "Я выбираю уважение к себе.",
        "Я позволяю себе быть настоящей.",

        // Отдых и восстановление
        "Отдых — это часть заботы, а не слабость.",
        "Я имею право на восстановление.",
        "Я разрешаю себе замедляться.",
        "Моё тело благодарно мне за отдых.",
        "Я могу ничего не делать и оставаться ценной.",
        "Восстановление — мой приоритет.",
        "Я выбираю баланс, а не истощение.",
        "Мне не нужно спешить.",
        "Я позволяю себе быть в процессе.",
        "Отдых поддерживает мою силу.",

        // Женская опора и устойчивость
        "Я доверяю своей внутренней устойчивости.",
        "Я умею быть мягкой и сильной одновременно.",
        "Я чувствую опору внутри себя.",
        "Я принимаю свои циклы и ритмы.",
        "Моя чувствительность — моя сила.",
        "Я могу быть в контакте с собой.",
        "Я выбираю бережное отношение к себе.",
        "Я позволяю себе чувствовать без осуждения.",
        "Я возвращаюсь к себе снова и снова.",
        "Я в безопасности быть собой."
    ]

    // MARK: - State

    private enum Phase: Equatable {
        case shuffling
        case revealing(cardId: Int)
        case revealed(cardId: Int)
    }

    @State private var cards: [PlayingCard] = []
    @State private var phase: Phase = .shuffling
    @State private var shuffleTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                Spacer()

                cardsArea
                    .frame(height: 440)
                    .padding(.horizontal, 20)

                Spacer()

                bottomActions
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
        }
        .onAppear {
            setupCards()
            startShuffle()
        }
        .onDisappear {
            shuffleTask?.cancel()
        }
    }

    // MARK: - UI

    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.05, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    Color(red: 0.15, green: 0.12, blue: 0.2).opacity(0.3),
                    Color.clear
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Карта дня")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                if phase == .shuffling {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 4, height: 4)
                        Text("Тасуем колоду...")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }

            Spacer()

            Button(action: onClose) {
                closeButtonContent
            }
        }
    }

    private var closeButtonContent: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 34, height: 34)

            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                .frame(width: 34, height: 34)

            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.75))
        }
    }

    private var cardsArea: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(cards) { card in
                    let selectedId: Int? = {
                        switch phase {
                        case .revealing(let id), .revealed(let id): return id
                        case .shuffling: return nil
                        }
                    }()

                    let isSelected = selectedId == card.id
                    let isRevealed: Bool = {
                        if case .revealed(let id) = phase { return id == card.id }
                        return false
                    }()

                    RealisticCardView(
                        card: card,
                        affirmation: affirmations[card.id % affirmations.count],
                        isRevealed: isRevealed,
                        isSelected: isSelected
                    )
                    .offset(card.offset)
                    .rotationEffect(.degrees(card.rotation))
                    .rotation3DEffect(
                        .degrees(card.tilt),
                        axis: (x: 1, y: 0, z: 0)
                    )
                    .scaleEffect(card.scale)
                    .opacity(card.opacity)
                    .zIndex(Double(card.zOrder))
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: card.tilt)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var bottomActions: some View {
        VStack(spacing: 14) {
            if case .revealed = phase {
                doneButton
                restartButton
            } else {
                EmptyView()
            }
        }
    }

    private var doneButton: some View {
        Button(action: {
            hapticImpact(.light)
            onClose()
        }) {
            Text("Готово")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.95, green: 0.95, blue: 0.97)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        }
    }

    private var restartButton: some View {
        Button(action: {
            hapticImpact(.light)
            restart()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .bold))
                Text("Еще карта")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
            )
        }
    }

    // MARK: - Logic

    private func setupCards() {
        var newCards: [PlayingCard] = []
        newCards.reserveCapacity(9)

        for index in 0..<9 {
            let x = CGFloat(index - 4) * 14
            let y = 110 + CGFloat(index) * 6
            let rotation = Double(index - 4) * 4
            let scale: CGFloat = 0.86 + CGFloat(index) * 0.016

            newCards.append(
                PlayingCard(
                    id: index,
                    offset: CGSize(width: x, height: y),
                    rotation: rotation,
                    scale: scale,
                    opacity: 1.0,
                    zOrder: index,
                    tilt: 0
                )
            )
        }

        cards = newCards
    }

    private func startShuffle() {
        shuffleTask?.cancel()
        phase = .shuffling

        shuffleTask = Task {
            await performSpread()
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }

            await performStack()
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            await performFan()
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                autoPickAndReveal()
            }
        }
    }

    @MainActor
    private func autoPickAndReveal() {
        guard !cards.isEmpty else { return }

        let picked = cards.randomElement()!.id
        phase = .revealing(cardId: picked)
        hapticImpact(.medium)

        animateSelection(cardId: picked)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            self.hapticImpact(.heavy)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                self.phase = .revealed(cardId: picked)
            }
        }
    }

    @MainActor
    private func animateSelection(cardId: Int) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.74)) {
            for i in cards.indices {
                if cards[i].id == cardId {
                    cards[i].offset = .zero
                    cards[i].rotation = 0
                    cards[i].scale = 1.02
                    cards[i].opacity = 1.0
                    cards[i].tilt = 0
                    cards[i].zOrder = 200
                } else {
                    cards[i].opacity = 0.08
                    cards[i].scale = 0.78
                }
            }
        }
    }

    private func performSpread() async {
        await MainActor.run {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                for i in 0..<cards.count {
                    let side: CGFloat = i <= 4 ? -1 : 1
                    let dist: CGFloat = 170 + CGFloat(Int.random(in: -20...20))
                    cards[i].offset = CGSize(width: side * dist, height: 40 + CGFloat(i * 12))
                    cards[i].rotation = Double(side) * Double(22 + Int.random(in: -7...7))
                    cards[i].tilt = Double(Int.random(in: -3...3))
                    cards[i].opacity = 1.0
                }
            }
        }
    }

    private func performStack() async {
        let order = cards.indices.shuffled()
        var stackY: CGFloat = 90

        for idx in order {
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.76)) {
                    cards[idx].offset = CGSize(
                        width: CGFloat(Int.random(in: -12...12)),
                        height: stackY
                    )
                    cards[idx].rotation = Double(Int.random(in: -6...6))
                    cards[idx].tilt = Double(Int.random(in: -2...2))
                    cards[idx].zOrder = Int(stackY)
                    cards[idx].scale = 0.88
                    cards[idx].opacity = 1.0
                }
            }
            stackY += 7
            try? await Task.sleep(nanoseconds: 120_000_000)
        }
    }

    private func performFan() async {
        await MainActor.run {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
                for i in 0..<cards.count {
                    let spreadX = CGFloat(i - 4) * 20
                    let arcY = 110 + abs(CGFloat(i - 4)) * 12

                    cards[i].offset = CGSize(width: spreadX, height: arcY)
                    cards[i].rotation = Double(i - 4) * 5
                    cards[i].scale = 0.88
                    cards[i].tilt = Double(i - 4) * -0.5
                    cards[i].zOrder = i
                    cards[i].opacity = 1.0
                }
            }
        }
    }

    private func restart() {
        setupCards()
        startShuffle()
    }

    private func hapticImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: style).impactOccurred()
        #endif
    }
}

// MARK: - Models

private struct PlayingCard: Identifiable {
    let id: Int
    var offset: CGSize
    var rotation: Double
    var scale: CGFloat
    var opacity: Double
    var zOrder: Int
    var tilt: Double
}

// MARK: - Realistic Card View

private struct RealisticCardView: View {
    let card: PlayingCard
    let affirmation: String
    let isRevealed: Bool
    let isSelected: Bool

    var body: some View {
        ZStack {
            cardBase

            if isRevealed {
                revealedContent
            } else {
                cardBack
            }
        }
        .frame(width: 270, height: 380)
    }

    private var cardBase: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(cardGradient)
                .overlay(cardShine)
                .overlay(cardStroke)
                .shadow(color: Color.black.opacity(0.35), radius: 28, x: 0, y: 14)
                .shadow(color: Color.black.opacity(0.2), radius: 52, x: 0, y: 28)

            if isSelected {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
        }
    }

    private var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.98, blue: 1.0),
                Color(red: 0.96, green: 0.96, blue: 0.98),
                Color(red: 0.94, green: 0.94, blue: 0.96)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardShine: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.4),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .center
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var cardStroke: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(strokeGradient, lineWidth: 1.5)
    }

    private var strokeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.95),
                Color.white.opacity(0.6),
                Color.white.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var revealedContent: some View {
        VStack(spacing: 16) {
            topOrnament
            Spacer(minLength: 0)
            affirmationText
            Spacer(minLength: 0)
            bottomOrnament
        }
        .padding(26)
    }

    private var topOrnament: some View {
        HStack {
            VStack(spacing: 2) {
                Circle()
                    .fill(dotGradient)
                    .frame(width: 6, height: 6)
                Rectangle()
                    .fill(dotGradient)
                    .frame(width: 1, height: 16)
            }
            Spacer()
        }
    }

    private var bottomOrnament: some View {
        HStack {
            Spacer()
            VStack(spacing: 2) {
                Rectangle()
                    .fill(dotGradient)
                    .frame(width: 1, height: 16)
                Circle()
                    .fill(dotGradient)
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var affirmationText: some View {
        VStack(spacing: 10) {
            Rectangle()
                .fill(dotGradient.opacity(0.3))
                .frame(width: 40, height: 1.5)

            Text(affirmation)
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(Color(red: 0.08, green: 0.08, blue: 0.1))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 14)

            Rectangle()
                .fill(dotGradient.opacity(0.3))
                .frame(width: 40, height: 1.5)
        }
    }

    private var dotGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.15, green: 0.15, blue: 0.2),
                Color(red: 0.12, green: 0.12, blue: 0.16)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardBack: some View {
        ZStack {
            ornatePattern
            centerMandala
        }
    }

    private var ornatePattern: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(patternStroke, lineWidth: 1)
                .padding(16)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(patternStroke, lineWidth: 0.5)
                .padding(20)

            VStack {
                HStack {
                    cornerOrnament
                    Spacer()
                    cornerOrnament.rotationEffect(.degrees(90))
                }
                Spacer()
                HStack {
                    cornerOrnament.rotationEffect(.degrees(-90))
                    Spacer()
                    cornerOrnament.rotationEffect(.degrees(180))
                }
            }
            .padding(30)
        }
    }

    private var cornerOrnament: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(patternStroke)
                .frame(width: 4, height: 4)
            Rectangle()
                .fill(patternStroke)
                .frame(width: 1, height: 12)
        }
    }

    private var patternStroke: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.14).opacity(0.15),
                Color(red: 0.08, green: 0.08, blue: 0.12).opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var centerMandala: some View {
        ZStack {
            Circle()
                .stroke(mandalaStroke, lineWidth: 1)
                .frame(width: 120, height: 120)

            Circle()
                .stroke(mandalaStroke, lineWidth: 0.5)
                .frame(width: 100, height: 100)

            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(mandalaStroke)
                    .frame(width: 1, height: 50)
                    .offset(y: -25)
                    .rotationEffect(.degrees(Double(index) * 45))
            }

            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.2))
        }
    }

    private var mandalaStroke: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.12),
                Color(red: 0.08, green: 0.08, blue: 0.12).opacity(0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    AffirmationMagicView { }
}
