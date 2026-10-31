import SwiftUI

struct ContentView: View {
    @ObservedObject var store: PhraseStore
    @State private var newPhrase = ""
    @State private var editingPhrase: PersonalPhrase?

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
                        Label("Todavía no has agregado frases.", systemImage: "text.quote")
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
                        TextField("Escribe una frase propia…", text: $newPhrase, axis: .vertical)
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
                        .accessibilityLabel("Agregar frase")
                    }
                } header: {
                    Label("Mis frases (\(store.phrases.count))", systemImage: "text.quote")
                } footer: {
                    Text("Toca una frase para editarla. Deslízala a la izquierda para eliminarla. Se guardan solo en este iPhone.")
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
                        Text("\(store.dailyTimes.count) / 64")
                            .foregroundStyle(store.dailyTimes.count > 64 ? Color.red : Color.secondary)
                    }
                } header: {
                    Label("Horario", systemImage: "clock")
                } footer: {
                    Text("Se envían avisos hasta antes de la hora final. Si inicio y final son iguales, se usan 24 horas. Los horarios nocturnos también funcionan.")
                }

                Section {
                    Button {
                        Task { await store.applySchedule() }
                    } label: {
                        HStack {
                            Spacer()
                            if store.isApplying {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Label("Guardar y programar", systemImage: "bell.badge.fill")
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
                        Image(systemName: store.hasError ? "exclamationmark.triangle" : "checkmark.circle")
                            .foregroundStyle(store.hasError ? Color.red : Color.green)
                    }
                } header: {
                    Text("Aplicar cambios")
                } footer: {
                    Text("Después de agregar, editar o borrar frases, o cambiar el horario, pulsa «Guardar y programar» para actualizar los avisos. Cada horario conserva su frase hasta la siguiente programación.")
                }
            }
            .navigationTitle("Frases Personales")
            .sheet(item: $editingPhrase) { phrase in
                EditPhraseSheet(phrase: phrase) { edited in
                    store.updatePhrase(id: phrase.id, text: edited)
                }
            }
            .task {
                await store.refreshScheduledCount()
            }
        }
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
                Section("Editar frase") {
                    TextField("Frase", text: $draft, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Editar frase")
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
