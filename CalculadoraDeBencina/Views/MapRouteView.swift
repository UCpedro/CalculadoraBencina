import MapKit
import SwiftUI

struct MapRouteView: View {
    @ObservedObject var viewModel: TripPlannerViewModel

    var body: some View {
        MapReader { proxy in
            Map(position: $viewModel.cameraPosition) {
                ForEach(viewModel.stops) { stop in
                    Annotation(stop.name, coordinate: stop.coordinate) {
                        VStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                            Text(stop.name)
                                .font(.caption2)
                                .padding(4)
                                .background(.thinMaterial, in: Capsule())
                        }
                    }
                }

                ForEach(viewModel.segments) { segment in
                    if let polyline = segment.polyline {
                        MapPolyline(polyline)
                            .stroke(.blue, lineWidth: 5)
                    } else {
                        MapPolyline(coordinates: [segment.from.coordinate, segment.to.coordinate])
                            .stroke(.orange, style: StrokeStyle(lineWidth: 3, dash: [6]))
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .onTapGesture { screenPoint in
                if let coordinate = proxy.convert(screenPoint, from: .local) {
                    withAnimation(.easeInOut) {
                        viewModel.addStop(at: coordinate)
                    }
                }
            }
        }
    }
}
