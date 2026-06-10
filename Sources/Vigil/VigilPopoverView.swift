import AppKit

@MainActor
final class VigilPopoverView: NSView, NSTextFieldDelegate {
    var onToggleWakelock: (() -> Void)?
    var onThresholdChange: ((Int) -> Void)?
    var onToggleLaunchAtLogin: (() -> Void)?
    var onQuit: (() -> Void)?

    private let headerLabel = NSTextField.vigilLabel()
    private let statusRule = NSView()
    private let statusLabel = NSTextField.vigilLabel()
    private let toggleButton = NSButton(title: "", target: nil, action: nil)
    private let thresholdField = NSTextField()
    private let batteryLabel = NSTextField.vigilLabel()
    private let warningLabel = NSTextField.vigilLabel()
    private let launchButton = NSButton(title: "", target: nil, action: nil)
    private let quitButton = NSButton(title: "Quit Vigil", target: nil, action: nil)
    private let aboutLabel = NSTextField.vigilLabel()
    private var lastThresholdText = "\(BatteryGuardSettings.defaultThreshold)"

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        buildView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        translatesAutoresizingMaskIntoConstraints = false
        buildView()
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 336, height: 392)
    }

    func configure(with state: VigilMenuState) {
        headerLabel.attributedStringValue = NSAttributedString(
            string: state.headerText,
            attributes: [
                .font: DesignTokens.Typography.displayEyebrow(),
                .foregroundColor: DesignTokens.Color.textSecondary,
                .kern: 0
            ]
        )

        statusLabel.attributedStringValue = NSAttributedString(
            string: state.statusText,
            attributes: [
                .font: DesignTokens.Typography.bodySmall(),
                .foregroundColor: state.isActive ? DesignTokens.Color.textPrimary : DesignTokens.Color.textSecondary,
                .kern: 0
            ]
        )
        statusRule.isHidden = !state.isActive

        configureRowButton(
            toggleButton,
            title: state.toggleText,
            color: state.isActive ? DesignTokens.Color.accentEmber : DesignTokens.Color.textPrimary
        )

        lastThresholdText = state.thresholdText
        if thresholdField.stringValue != state.thresholdText {
            thresholdField.stringValue = state.thresholdText
        }

        warningLabel.stringValue = state.warningText ?? ""
        warningLabel.isHidden = state.warningText == nil

        batteryLabel.stringValue = state.batteryText ?? ""
        batteryLabel.isHidden = state.batteryText == nil

        configureRowButton(
            launchButton,
            title: state.launchAtLoginText,
            color: DesignTokens.Color.textPrimary
        )

        aboutLabel.attributedStringValue = NSAttributedString(
            string: state.aboutText,
            attributes: [
                .font: DesignTokens.Typography.aboutVersion(),
                .foregroundColor: DesignTokens.Color.textTertiary,
                .kern: 0
            ]
        )
    }

    private func buildView() {
        wantsLayer = true
        layer?.backgroundColor = DesignTokens.Color.surfaceRaised.cgColor
        layer?.borderColor = DesignTokens.Color.ink700.cgColor
        layer?.borderWidth = 1
        layer?.cornerRadius = DesignTokens.Radius.r8
        layer?.masksToBounds = true

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DesignTokens.Space.x5),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DesignTokens.Space.x5),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: DesignTokens.Space.x5),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DesignTokens.Space.x5)
        ])

        headerLabel.lineBreakMode = .byTruncatingTail
        stack.addArrangedSubview(fullWidth(headerLabel))

        addSpacer(DesignTokens.Space.x4, to: stack)
        stack.addArrangedSubview(statusRow())
        addDivider(to: stack)
        stack.addArrangedSubview(configuredButton(toggleButton, action: #selector(togglePressed)))
        addDivider(to: stack)
        stack.addArrangedSubview(thresholdSection())
        addDivider(to: stack)
        stack.addArrangedSubview(configuredButton(launchButton, action: #selector(launchPressed)))
        stack.addArrangedSubview(configuredButton(quitButton, action: #selector(quitPressed), textColor: DesignTokens.Color.textSecondary))
        addSpacer(DesignTokens.Space.x4, to: stack)
        stack.addArrangedSubview(fullWidth(aboutLabel))
    }

    private func statusRow() -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.wantsLayer = true
        row.layer?.backgroundColor = DesignTokens.Color.surfaceRaised.cgColor

        statusRule.translatesAutoresizingMaskIntoConstraints = false
        statusRule.wantsLayer = true
        statusRule.layer?.backgroundColor = DesignTokens.Color.accentEmber.cgColor

        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(statusRule)
        row.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 44),
            row.widthAnchor.constraint(equalToConstant: 296),

            statusRule.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            statusRule.topAnchor.constraint(equalTo: row.topAnchor),
            statusRule.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            statusRule.widthAnchor.constraint(equalToConstant: 3),

            statusLabel.leadingAnchor.constraint(equalTo: statusRule.trailingAnchor, constant: DesignTokens.Space.x3),
            statusLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    private func thresholdSection() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = DesignTokens.Space.x2
        stack.translatesAutoresizingMaskIntoConstraints = false

        let topRow = NSView()
        topRow.translatesAutoresizingMaskIntoConstraints = false

        let label = NSTextField.vigilLabel("Auto-disable below")
        label.font = DesignTokens.Typography.uiLabel()
        label.textColor = DesignTokens.Color.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false

        let inputShell = NSView()
        inputShell.translatesAutoresizingMaskIntoConstraints = false
        inputShell.wantsLayer = true
        inputShell.layer?.backgroundColor = DesignTokens.Color.surfaceSunken.cgColor
        inputShell.layer?.cornerRadius = DesignTokens.Radius.r6
        inputShell.layer?.borderColor = DesignTokens.Color.ink700.cgColor
        inputShell.layer?.borderWidth = 1

        thresholdField.translatesAutoresizingMaskIntoConstraints = false
        thresholdField.isBordered = false
        thresholdField.drawsBackground = false
        thresholdField.focusRingType = .none
        thresholdField.font = DesignTokens.Typography.codeDefault()
        thresholdField.textColor = DesignTokens.Color.textPrimary
        thresholdField.alignment = .right
        thresholdField.delegate = self
        thresholdField.target = self
        thresholdField.action = #selector(thresholdSubmitted)

        let percent = NSTextField.vigilLabel("%")
        percent.font = DesignTokens.Typography.codeDefault()
        percent.textColor = DesignTokens.Color.textTertiary
        percent.translatesAutoresizingMaskIntoConstraints = false

        inputShell.addSubview(thresholdField)
        inputShell.addSubview(percent)

        topRow.addSubview(label)
        topRow.addSubview(inputShell)

        batteryLabel.font = DesignTokens.Typography.bodySmall()
        batteryLabel.textColor = DesignTokens.Color.textSecondary
        batteryLabel.translatesAutoresizingMaskIntoConstraints = false

        warningLabel.font = DesignTokens.Typography.bodySmall()
        warningLabel.textColor = DesignTokens.Color.statusWarning
        warningLabel.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(topRow)
        stack.addArrangedSubview(batteryLabel)
        stack.addArrangedSubview(warningLabel)
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 296),

            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            topRow.widthAnchor.constraint(equalToConstant: 296),
            topRow.heightAnchor.constraint(equalToConstant: 32),

            label.leadingAnchor.constraint(equalTo: topRow.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: topRow.centerYAnchor),

            inputShell.trailingAnchor.constraint(equalTo: topRow.trailingAnchor),
            inputShell.centerYAnchor.constraint(equalTo: topRow.centerYAnchor),
            inputShell.widthAnchor.constraint(equalToConstant: 86),
            inputShell.heightAnchor.constraint(equalToConstant: 32),

            thresholdField.leadingAnchor.constraint(equalTo: inputShell.leadingAnchor, constant: DesignTokens.Space.x2),
            thresholdField.centerYAnchor.constraint(equalTo: inputShell.centerYAnchor),
            thresholdField.trailingAnchor.constraint(equalTo: percent.leadingAnchor, constant: -DesignTokens.Space.x1),

            percent.trailingAnchor.constraint(equalTo: inputShell.trailingAnchor, constant: -DesignTokens.Space.x2),
            percent.centerYAnchor.constraint(equalTo: inputShell.centerYAnchor),

            batteryLabel.widthAnchor.constraint(equalToConstant: 296),
            warningLabel.widthAnchor.constraint(equalToConstant: 296)
        ])

        return container
    }

    private func configuredButton(
        _ button: NSButton,
        action: Selector,
        textColor: NSColor = DesignTokens.Color.textPrimary
    ) -> NSButton {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.alignment = .left
        button.target = self
        button.action = action
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        button.widthAnchor.constraint(equalToConstant: 296).isActive = true
        configureRowButton(button, title: button.title, color: textColor)
        return button
    }

    private func configureRowButton(_ button: NSButton, title: String, color: NSColor) {
        button.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: DesignTokens.Typography.uiLabel(),
                .foregroundColor: color,
                .kern: 0
            ]
        )
    }

    private func addDivider(to stack: NSStackView) {
        addSpacer(DesignTokens.Space.x4, to: stack)

        let divider = NSView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.wantsLayer = true
        divider.layer?.backgroundColor = DesignTokens.Color.ink700.cgColor
        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.widthAnchor.constraint(equalToConstant: 296)
        ])
        stack.addArrangedSubview(divider)

        addSpacer(DesignTokens.Space.x4, to: stack)
    }

    private func addSpacer(_ height: CGFloat, to stack: NSStackView) {
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        stack.addArrangedSubview(spacer)
    }

    private func fullWidth(_ view: NSView) -> NSView {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: 296).isActive = true
        return view
    }

    @objc
    private func togglePressed() {
        onToggleWakelock?()
    }

    @objc
    private func thresholdSubmitted() {
        commitThreshold()
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        commitThreshold()
    }

    private func commitThreshold() {
        let filtered = thresholdField.stringValue.filter(\.isNumber)
        guard let value = Int(filtered) else {
            thresholdField.stringValue = lastThresholdText
            return
        }
        onThresholdChange?(value)
    }

    @objc
    private func launchPressed() {
        onToggleLaunchAtLogin?()
    }

    @objc
    private func quitPressed() {
        onQuit?()
    }
}

private extension NSTextField {
    static func vigilLabel(_ text: String = "") -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 2
        label.textColor = DesignTokens.Color.textPrimary
        label.font = DesignTokens.Typography.bodyDefault()
        label.backgroundColor = .clear
        return label
    }
}
