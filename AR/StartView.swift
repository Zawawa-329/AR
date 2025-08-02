//
//  StareView.swift
//  AR
//
//  Created by owner on 2025/07/31.
//

import SwiftUI


struct StartView: View {
    var userName: String
    @State private var showAR = false
    @State private var selectedMood: String? = nil
    
struct Question{
    let id = UUID()
    let text:String
    let options:[String]
    }
    let questions:[Question]=[
        Question(text:"今日の気分は⁇",options:["元気☺️","ちょっと元気🙂","普通😶","ちょっとお疲れ😕","お疲れ🥲"]),
        Question(text:"今の気分は⁇",options:["楽しい☺️","悲しい😭","何ともない😶","怒る😕","眠い🥱"]),
        Question(text:"お話は⁇",options:["たくさんしたい☺️","多めにしたい🙂","普通😶","あまりしたくない😕","したくない🥲"])
    ]
    
    @State private var answers: [Int: String] = [:]

    var body: some View {
        VStack(spacing: 40) {
            Text("こんにちは、\(userName) さん")
                .font(.title)
                .padding()
            
            ScrollView {
                VStack(spacing: 30) {
                    ForEach(Array(questions.enumerated()),id: \.1.id){
                        index, question in
                        VStack(alignment: .leading,spacing: 10){
                            Text(question.text)
                                .font(.headline)
                            
                            ForEach(question.options,id: \.self){
                                option in
                                Button(action: {
                                    answers[index] = option
                                }){
                                    HStack{
                                        Text(option)
                                            .foregroundColor(.black)
                                        Spacer()
                                        if answers[index] == option{
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                            
                                        }
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    if answers.count == questions.count {
                                Button(action: {
                                    showAR = true
                                }) {
                                    Text("カメラを起動する")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                }
                            }
                        }
                .padding(.vertical)
            }
            Spacer()

        }
        .fullScreenCover(isPresented: $showAR) {
            ContentView() // AR画面
        }
    }
}
