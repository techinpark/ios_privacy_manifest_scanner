import Foundation

struct HTMLTemplate {
    static func generateHTML(
        currentDate: String,
        rootDirectoryPath: String,
        scanDuration: String,
        with results: [SearchResult]
        ) -> String {
         var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Privacy Manifest Scanner Report</title>
            <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
        </head>
        <body class="bg-gray-50 p-5">
            <h1 class="text-3xl font-bold text-blue-600 mb-4">Privacy Manifest Scanner Report</h1>
            <ul class="list-none">
                <li class="font-semibold"><span class="text-gray-600">Scan Date:</span> \(currentDate)</li>
                <li class="font-semibold"><span class="text-gray-600">Root Directory:</span> \(rootDirectoryPath)</li>
                <li class="font-semibold text-red-500"><span class="text-gray-600">Issue Found:</span> \(results.count)</li>
                <li class="font-semibold"><span class="text-gray-600">Scan Duration:</span> \(scanDuration) seconds</li>
            </ul>
            <div class="overflow-x-auto mt-6">
                <table class="w-full table-auto bg-white rounded-lg overflow-hidden">
                    <thead class="bg-blue-500 text-white">
                        <tr>
                            <th class="px-4 py-2">Serial No.</th>
                            <th class="px-4 py-2">File Path</th>
                            <th class="px-4 py-2">Used API</th>
                            <th class="px-4 py-2">Line Content</th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-700">
        """

        for (index, result) in results.enumerated() {
            let rowClass = index % 2 == 0 ? "bg-gray-100" : "bg-white"
            let highlightedLineContent = result.lineContent.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: result.searchString, with: "<span class=\"text-red-500\">\(result.searchString)</span>")
            
            html += """
                        <tr class="\(rowClass)">
                            <td class="border px-4 py-2 font-semibold text-center">\(index + 1)</td>
                            <td class="border px-4 py-2">\(result.filePath):\(result.lineNumber)</td>
                            <td class="border px-4 py-2">\(result.searchString)</td>
                            <td class="border px-4 py-2 italic" style="white-space: pre-wrap;">\(highlightedLineContent)</td>
                        </tr>
            """
        }

        html += """
                    </tbody>
                </table>
            </div>
        </body>
        </html>
        """
        return html
    }
}