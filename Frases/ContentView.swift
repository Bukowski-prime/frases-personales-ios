import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var store: PhraseStore
    @State private var newPhrase = ""
    @State private var editingPhrase: PersonalPhrase?
    @State private var backupDocument: MessagesBackupDocument?
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var showingImportChoices = false
    @State private var importedMessages: [String] = []
    @State private var showingResult = false
    @State private var resultTitle = ""
    @State private var resultDetail = ""

    private var startTime: Binding<Date> {
        Binding(
            get: { store.date(for: store.startMinute) },
            set: { store.startMinute = store.minute(of: $0) }
        )
    }

    private var endTime: Binding<Date> {
        Binding(
            get: { store.date(for: store.endMinute) },
            set: { store.endMinute = store.minute(of: $0) }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if store.phrases.isEmpty {
                        Label("Todavía no hay mensajes guardados.", systemImage: "text.quote")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(store.phrases) { phrase in
                        Button {
                            editingPhrase = phrase
                        } label: {
                            HStack(spacing: 12) {
                                Text(phrase.text)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 8)
                                Image(systemName: "pencil")
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: store.deletePhrases)

                    HStack(alignment: .bottom, spacing: 12) {
                        TextField("Escribe un mensaje…", text: $newPhrase, axis: .vertical)
                            .lineLimit(1...4)
                            .textInputAutocapitalization(.sentences)
                        Button {
                            store.addPhrase(newPhrase)
                            newPhrase = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .disabled(newPhrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityLabel("Agregar mensaje")
                    }
                } footer: {
                    Text("\(store.phrases.count) mensajes guardados en este iPhone. Toca uno para editarlo o deslízalo hacia la izquierda para borrarlo.")
                }

                Section {
                    Button {
                        backupDocument = MessagesBackupDocument(messages: store.phrases.map(\.text))
                        showingExporter = true
                    } label: {
                        Label("Exportar respaldo", systemImage: "square.and.arrow.up")
                    }
                    .disabled(store.phrases.isEmpty)

                    Button {
                        showingImporter = true
                    } label: {
                        Label("Importar respaldo", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Copia de seguridad")
                } footer: {
                    Text("El archivo JSON contiene solamente tus mensajes. Puedes guardarlo en Archivos o iCloud Drive. Al importar, podrás combinarlos con los actuales o reemplazarlos. Después tendrás que pulsar «Guardar y programar».")
                }

                Section {
                    Toggle("Activar notificaciones", isOn: $store.notificationsEnabled)

                    Picker("Frecuencia", selection: $store.intervalMinutes) {
                        ForEach(PhraseStore.possibleIntervals, id: \.self) { minutes in
                            Text(intervalLabel(minutes)).tag(minutes)
                        }
                    }
                    DatePicker("Desde", selection: startTime, displayedComponents: .hourAndMinute)
                    DatePicker("Hasta", selection: endTime, displayedComponents: .hourAndMinute)

                    HStack {
                        Text("Avisos diarios")
                        Spacer()
                        Text("\(store.dailyTimes.count)")
                            .foregroundStyle(store.dailyTimes.count > 64 ? Color.red : Color.secondary)
                    }
                    Text("Los mensajes cambian de orden también entre días. La app prepara hasta 64 avisos futuros y los repone al abrirse; iOS puede intentar renovarlos en segundo plano, pero no lo garantiza.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Label("Horario", systemImage: "clock")
                } footer: {
                    Text("La hora final está incluida si coincide con el intervalo. Por ejemplo, de 7:00 a 20:00 cada 30 minutos son 27 avisos diarios. Si desde y hasta coinciden, se usan 24 horas sin duplicar la última hora.")
                }

                Section {
                    Button {
                        Task { await store.applySchedule() }
                    } label: {
                        HStack {
                            Spacer()
                            if store.isApplying {
                                ProgressView().padding(.trailing, 8)
                            }
                            Label(store.needsProgramming ? "Aplicar cambios pendientes" : "Guardar y programar", systemImage: "bell.badge.fill")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(store.isApplying)

                    Label {
                        Text(store.statusMessage)
                            .font(.subheadline)
                            .foregroundStyle(store.hasError ? Color.red : Color.secondary)
                    } icon: {
                        Image(systemName: store.hasError ? "exclamationmark.triangle" : (store.needsProgramming ? "arrow.clockwise.circle" : "checkmark.circle"))
                            .foregroundStyle(store.hasError ? Color.red : (store.needsProgramming ? Color.orange : Color.green))
                    }
                } header: {
                    Text("Notificaciones")
                } footer: {
                    Text("Para asegurar avisos continuos, abre la app cada 1–2 días. Con 27 avisos diarios, las 64 solicitudes cubren algo más de dos jornadas. No cierres la app a la fuerza si quieres que iOS tenga oportunidad de renovarlas en segundo plano.")
                }

                if let until = store.scheduledUntil {
                    Section("Cobertura programada") {
                        LabeledContent("Avisos pendientes", value: "\(store.scheduledCount)")
                        LabeledContent("Último aviso preparado") {
                            Text(until, format: .dateTime.weekday(.wide).day().month(.abbreviated).hour().minute())
                        }
                    }
                }

                if !store.upcomingNotices.isEmpty {
                    Section("Próximos avisos") {
                        ForEach(store.upcomingNotices) { notice in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(notice.date, format: .dateTime.weekday(.wide).day().month(.abbreviated).hour().minute())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(notice.text)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
            .disabled(store.isApplying)
            .navigationTitle("Avisos")
            .sheet(item: $editingPhrase) { phrase in
                EditPhraseSheet(phrase: phrase) { edited in
                    store.updatePhrase(id: phrase.id, text: edited)
                }
            }
            .task {
                await store.replenishIfNeeded()
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: backupDocument,
                contentType: .json,
                defaultFilename: "Avisos-respaldo"
            ) { result in
                switch result {
                case .success:
                    showResult(title: "Respaldo exportado", detail: "Comprueba que el archivo se guardó en la ubicación elegida.")
                case .failure(let error):
                    showResult(title: "No se pudo exportar", detail: error.localizedDescription)
                }
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
                Task { @MainActor in
                    switch result {
                    case .success(let url):
                        let hasAccess = url.startAccessingSecurityScopedResource()
                        defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
                        do {
                            let data = try Data(contentsOf: url)
                            importedMessages = try MessagesBackupDocument.decodeMessages(from: data)
                            showingImportChoices = true
                        } catch {
                            showResult(title: "No se pudo importar", detail: error.localizedDescription)
                        }
                    case .failure(let error):
                        showResult(title: "No se pudo abrir el archivo", detail: error.localizedDescription)
                    }
                }
            }
            .confirmationDialog(
                "Restaurar respaldo",
                isPresented: $showingImportChoices,
                titleVisibility: .visible
            ) {
                Button("Combinar con los mensajes actuales") {
                    finishImport(replacing: false)
                }
                Button("Reemplazar todos los mensajes", role: .destructive) {
                    finishImport(replacing: true)
                }
                Button("Cancelar", role: .cancel) {
                    importedMessages = []
                }
            } message: {
                Text("El archivo contiene \(importedMessages.count) mensajes. Combinar evita duplicados. Reemplazar borrará tus mensajes actuales. Esta acción no modifica el horario.")
            }
            .alert(resultTitle, isPresented: $showingResult) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(resultDetail)
            }
        }
    }

    private func showResult(title: String, detail: String) {
        resultTitle = title
        resultDetail = detail
        showingResult = true
    }

    private func finishImport(replacing: Bool) {
        let result = store.restoreMessages(importedMessages, replacing: replacing)
        importedMessages = []
        showResult(
            title: "Respaldo importado",
            detail: "Se incorporaron \(result.imported) mensajes. Total: \(result.total). Pulsa «Guardar y programar» para actualizar las próximas notificaciones."
        )
    }

    private func intervalLabel(_ minutes: Int) -> String {
        if minutes == 1440 { return "Cada 24 horas" }
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            if m == 0 { return "Cada \(h) hora\(h == 1 ? "" : "s")" }
            return "Cada \(h) h \(m) min"
        }
        return "Cada \(minutes) minutos"
    }
}

private struct EditPhraseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: String
    let onSave: (String) -> Void

    init(phrase: PersonalPhrase, onSave: @escaping (String) -> Void) {
        _draft = State(initialValue: phrase.text)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Editar mensaje") {
                    TextField("Mensaje", text: $draft, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Editar mensaje")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
