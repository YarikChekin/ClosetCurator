import SwiftUI
import SwiftData
import PhotosUI

struct StyleBoardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var styleBoards: [StyleBoard]
    @State private var showingCreateBoard = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(styleBoards) { board in
                    NavigationLink(destination: StyleBoardDetailView(board: board)) {
                        StyleBoardRow(board: board)
                    }
                }
                .onDelete { indices in
                    for index in indices {
                        modelContext.delete(styleBoards[index])
                    }
                }
            }
            .navigationTitle("Style Boards")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateBoard = true }) {
                        Label("Create Board", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateBoard) {
                CreateStyleBoardView()
            }
            .overlay {
                if styleBoards.isEmpty {
                    ContentUnavailableView(
                        label: {
                            Label("No Style Boards", systemImage: "square.grid.2x2")
                        },
                        description: {
                            Text("Create style boards to collect outfit inspiration and refine your style preferences.")
                        },
                        actions: {
                            Button("Create Style Board") {
                                showingCreateBoard = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    )
                }
            }
        }
    }
}

struct StyleBoardRow: View {
    let board: StyleBoard
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
            Text(board.name)
                .font(.headline)
            
            if let description = board.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.secondaryColor)
                    .lineLimit(1)
            }
            
            HStack(spacing: DesignTokens.spacing8) {
                if let season = board.season {
                    Text(season.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, DesignTokens.spacing8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
                }
                
                if let occasion = board.occasion {
                    Text(occasion.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, DesignTokens.spacing8)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
                }
                
                Spacer()
                
                Text("\(board.items.count) items")
                    .font(.caption)
                    .foregroundColor(DesignTokens.secondaryColor)
            }
        }
        .padding(.vertical, DesignTokens.spacing8)
        .contentShape(Rectangle())
        .frame(minHeight: DesignTokens.minTappable)
    }
}

#Preview {
    StyleBoardView()
        .modelContainer(for: [StyleBoard.self, StyleBoardItem.self])
} 