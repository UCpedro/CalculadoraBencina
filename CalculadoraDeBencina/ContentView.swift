import MapKit
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TripPlannerViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MapRouteView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                panel
            }
            .navigationTitle("Calculadora de Bencina")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.requestCurrentLocationAsStart()
                    } label: {
                        Label("Ubicación actual", systemImage: "location.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        withAnimation { viewModel.clearRoute() }
                    } label: {
                        Label("Limpiar", systemImage: "trash")
                    }
                    .disabled(viewModel.stops.isEmpty)
                }
            }
            .alert("Aviso", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("OK") { viewModel.errorMessage = nil }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
        }
        .onChange(of: viewModel.kmPerLiterInput) { _, _ in Task { await viewModel.refreshRoutes() } }
        .onChange(of: viewModel.fuelPriceInput) { _, _ in Task { await viewModel.refreshRoutes() } }
    }

    private var panel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                inputs
                searchSection
                stopsSection
                segmentsSection
                summaryCard
            }
            .padding()
        }
        .frame(maxHeight: 390)
        .background(.ultraThinMaterial)
    }

    private var inputs: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Datos del vehículo")
                .font(.headline)

            HStack {
                TextField("Rendimiento (km/L)", text: $viewModel.kmPerLiterInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                TextField("Precio por litro", text: $viewModel.fuelPriceInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }

            Picker("Tipo de bencina", selection: $viewModel.selectedFuelType) {
                ForEach(FuelType.allCases) { fuel in
                    Text(fuel.label).tag(fuel)
                }
            }
            .pickerStyle(.segmented)

            if let validation = viewModel.inputValidationMessage {
                Text(validation)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Buscar y agregar parada")
                .font(.headline)

            HStack {
                TextField("Buscar dirección o lugar", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                Button("Buscar") { viewModel.searchPlaces() }
                    .buttonStyle(.borderedProminent)
            }

            if !viewModel.searchResults.isEmpty {
                ForEach(viewModel.searchResults.prefix(5), id: \.self) { item in
                    Button {
                        withAnimation(.easeInOut) {
                            viewModel.addStop(from: item)
                            viewModel.searchText = ""
                            viewModel.searchResults = []
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "Sin nombre")
                                .font(.subheadline)
                            Text(item.placemark.title ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var stopsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Paradas")
                .font(.headline)
            if viewModel.stops.isEmpty {
                Text("Toca el mapa o usa la búsqueda para agregar paradas.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(viewModel.stops.enumerated()), id: \.element.id) { index, stop in
                    HStack(spacing: 8) {
                        Text("\(index + 1). \(stop.name)")
                        Spacer()
                        Button {
                            withAnimation {
                                viewModel.removeStops(at: IndexSet(integer: index))
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.caption)
                }
            }

            if viewModel.stops.count >= 2 {
                HStack {
                    Button("Subir última") {
                        withAnimation {
                            viewModel.moveStop(from: IndexSet(integer: viewModel.stops.count - 1), to: max(viewModel.stops.count - 2, 0))
                        }
                    }
                    .buttonStyle(.bordered)

                    Button("Bajar primera") {
                        withAnimation {
                            viewModel.moveStop(from: IndexSet(integer: 0), to: min(2, viewModel.stops.count))
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var segmentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Detalle por tramo")
                .font(.headline)

            if viewModel.segments.isEmpty {
                Text("Agrega al menos 2 paradas para calcular tramos.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(viewModel.segments.enumerated()), id: \.element.id) { index, segment in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trayecto \(index + 1): \(segment.from.name) → \(segment.to.name)")
                            .font(.subheadline.bold())
                        Text("Distancia: \(Formatters.distanceKm(fromMeters: segment.distanceMeters))")
                        Text("Litros: \(Formatters.liters(segment.liters(consumption: viewModel.kmPerLiter)))")
                        Text("Costo: \(Formatters.currency(segment.cost(consumption: viewModel.kmPerLiter, pricePerLiter: viewModel.fuelPrice)))")
                        if segment.expectedTravelTime > 0 {
                            Text("Duración estimada: \(Formatters.duration(segment.expectedTravelTime))")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.caption)
                    .padding(8)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Total del viaje")
                .font(.headline)
            Text("Distancia total: \(Formatters.distanceKm(fromMeters: viewModel.summary.totalDistanceMeters))")
            Text("Litros totales: \(Formatters.liters(viewModel.summary.totalLiters))")
            Text("Gasto total: \(Formatters.currency(viewModel.summary.totalCost))")
                .font(.title3.bold())
            if viewModel.summary.totalDuration > 0 {
                Text("Duración total estimada: \(Formatters.duration(viewModel.summary.totalDuration))")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [.blue.opacity(0.2), .green.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 14)
        )
    }
}

#Preview {
    ContentView()
}
