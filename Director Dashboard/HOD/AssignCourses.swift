//
//  AssignCourses.swift
//  Director Dashboard
//
//  Created by ADJ on 13/01/2024.
//

import SwiftUI


struct AssignCourse: View { // Design 100% ok
    
    @StateObject private var coursesViewModel = CoursesViewModel()
    @StateObject private var facultiesViewModel = FacultiesViewModel()
    var facultyID: Int
    var facultyName: String
    @State private var searchText = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCourses: Set<Int> = []
    @State private var selectedfaculty = 0
    
    var filteredcourse: [AllCourses] { // All Data Will Be Filter and show on Table
        if searchText.isEmpty {
            return coursesViewModel.existing
        } else {
            return coursesViewModel.existing.filter { faculty in
                faculty.c_code.localizedCaseInsensitiveContains(searchText) ||
                faculty.c_title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    struct SearchBar: View { // Search Bar avaible outside of table to search record
        
        @Binding var text: String
        
        var body: some View {
            HStack {
                TextField("Search", text: $text)
                    .padding()
                    .frame(width: 247 , height: 40)
                    .background(Color.gray.opacity(1))
                    .cornerRadius(8) // Set the corner radius to round the corners
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color.red.opacity(0.9))
                }
                .opacity(text.isEmpty ? 0 : 1)
                Spacer()
            }
        }
    }
    
    var body: some View { // Get All Data From Node MongoDB : Pending
        
        VStack {
            Text("Assign Course")
                .bold()
                .font(.largeTitle)
                .foregroundColor(Color.white)
         
            VStack{
                Spacer()
                Picker(selection: $selectedfaculty, label: Text("ggggg")) {
                    ForEach(facultiesViewModel.remaining, id: \.f_id) { faculty in
                        Text(faculty.f_name)
                            .tag(faculty.f_id)
                    }
                }
                .pickerStyle(.menu)
                .accentColor(Color.green)
                .onChange(of: Optional(selectedfaculty)) { selectedFacultyID in
                    if let selectedfacultyID = selectedFacultyID {
                        print("Selected Fauclty ID: \(selectedfacultyID)")
                    }
                }
                
                Spacer()
                SearchBar(text: $searchText)
                Spacer()
                VStack{
                    ScrollView{
                        ForEach(filteredcourse, id: \.self) { cr in
                            HStack{
                                
                                Text(cr.c_title)
                                    .font(.headline)
                                    .foregroundColor(Color.white)
                                    .padding(.horizontal)
                                    .frame(maxWidth: .infinity , alignment: .leading)
                                Button(action: {
                                    toggleCourseSelection(courseID: cr.c_id)
                                    assignCourseToFaculty(courseID: cr.c_id, facultyID: facultyID)
                                }) {
                                    Image(systemName: selectedCourses.contains(cr.c_id) ? "checkmark.square.fill" : "square")
                                        .font(.title2)
                                        .foregroundColor(Color.white)
                                        .padding(.horizontal)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }
                            Divider()
                                .background(Color.white)
                                .padding(1)
                        }
                        if filteredcourse.isEmpty {
                            Text("No Course Found")
                                .font(.headline)
                                .foregroundColor(.orange)
                                .padding()
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                )
                .frame(height: 500)
                .onAppear {
                    coursesViewModel.fetchExistingCourses()
                }
            }
            .onAppear {
                facultiesViewModel.fetchExistingFaculties()
            }
            Spacer()
            
        }
        .navigationBarItems(leading: backButton)
        .background(Image("fc").resizable().ignoresSafeArea())
    }
    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.blue)
                .imageScale(.large)
        }
    }
    private func toggleCourseSelection(courseID: Int) {
        if selectedCourses.contains(courseID) {
            selectedCourses.remove(courseID)
        } else {
            selectedCourses.insert(courseID)
        }
    }
    private func assignSelectedCourses() {
        // Iterate over the selected courses
        for courseID in selectedCourses {
            // Make the API call to assign the course to the faculty
            assignCourseToFaculty(courseID: courseID,facultyID: facultyID)
        }
    }
    private func assignCourseToFaculty(courseID: Int, facultyID: Int) {
        let url = URL(string: "http://localhost:2000/assigncoursetofaculty")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let parameters: [String: Any] = [
            "f_id": facultyID,
            "c_id": courseID
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                // Handle the error as needed
                return
            }
            
            guard let data = data else {
                print("No data received")
                // Handle the absence of data as needed
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let message = json["message"] as? String {
                        print(message)
                        // Update the UI or perform any other action based on the message
                    }
                } else {
                    print("Invalid JSON response")
                    // Handle the invalid JSON response as needed
                }
            } catch {
                print("Error parsing JSON response: \(error)")
                // Handle the JSON parsing error as needed
            }
        }.resume()
    }
}

struct AssignCourse_Previews: PreviewProvider {
    static var previews: some View {
        AssignCourse(facultyID: 1, facultyName: "")
    }
}
