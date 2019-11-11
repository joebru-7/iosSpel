//
//  GameScene.swift
//  Joels spel
//
//  Created by admin on 2019-10-25.
//  Copyright © 2019 admin. All rights reserved.
//

import SpriteKit
import GameplayKit

protocol CanReceiveTransitionEvents {
    func viewWillTransition(to size: CGSize)
}

extension UserDefaults {
    open func setStruct<T: Codable>(_ value: T?, forKey defaultName: String){
        let data = try? JSONEncoder().encode(value)
        set(data, forKey: defaultName)
    }

    open func structData<T>(_ type: T.Type, forKey defaultName: String) -> T? where T : Decodable {
        guard let encodedData = data(forKey: defaultName) else {
            return nil
        }
        
        return try! JSONDecoder().decode(type, from: encodedData)
    }
}

let colors = [UIColor.blue,UIColor.red,UIColor.green,UIColor.orange,UIColor.yellow,UIColor.black]


struct Highscore:Codable
{
    var a:Int
    var b:Int
    var c:Int
    var d:Int
    var e:Int
    var f:Int
    
    mutating func Sort(){
        var arr = [a,b,c,d,e,f]
        arr.sort()
        a=arr[0]
        b=arr[1]
        c=arr[2]
        d=arr[3]
        e=arr[4]
        f=arr[5]
    }
}

func removeHighScore(){
    UserDefaults.standard.removeObject(forKey: "hs")
}

func storeHighScore(hs:Highscore) {
    UserDefaults.standard.setStruct(hs, forKey: "hs")
}

func getHighScore()->Highscore?
{
    if let hs = UserDefaults.standard.structData(Highscore.self, forKey: "hs")
    {
        return hs
    }
    return nil
}

class Ball {
    var shape :SKShapeNode
    var pos = CGPoint(x:0,y:0)
    var angle:CGFloat = 1 //radians
    var speed:CGFloat = 1.0
    var type = 0
    var parent:GameScene
    var captured = false
    
    init(pos:CGPoint,type:Int,parent:GameScene){
        shape = SKShapeNode.init(circleOfRadius: 10)
        shape.position = pos
        self.pos = pos
        self.type = type
        shape.fillColor = colors[type]
        angle = CGFloat.random(in:0 ... .pi*2)
        self.parent=parent
    }
    
    func capture()
    {
        shape.removeFromParent()
        captured = true
        parent.checkWin = true
    }
    
    func update(){
        
        angle += CGFloat.random(in:-0.05...0.05)
        speed += CGFloat.random(in:-0.01...0.01)
        
        pos.x += cos(angle) * speed
        pos.y += sin(angle) * speed
        
        let w = parent.size.width / 2 - 10
        if pos.x < -w || pos.x >  w{
            angle = (.pi - angle).truncatingRemainder(dividingBy: (.pi * 2))
        }
        let h = parent.size.height / 2 - 10
        if pos.y < -h || pos.y > h{
            angle = -angle.truncatingRemainder(dividingBy: (.pi * 2))
        }
        
        shape.position = pos
    }
    
}

class Line {
    var closerPath = CGMutablePath()
    private var path = CGMutablePath()
    let shape = SKShapeNode()
    let shape2 = SKShapeNode()
    var points = [] as [CGPoint]
    var parent:GameScene
    var ttl = 60*20
    
    init(pos:CGPoint,parent:GameScene){
        self.parent=parent
        path.move(to: pos)
        shape.strokeColor = UIColor.white
        shape.lineWidth = 2
        parent.addChild(shape)
        
        shape2.strokeColor = UIColor.white
        shape2.lineWidth = 2
        parent.addChild(shape2)
        
        points.append(pos)
        
    }

    func addPoint(pos:CGPoint){
        path.addLine(to: pos)
        points.append(pos)
        
        closerPath = CGMutablePath()
        closerPath.move(to: pos)
        closerPath.addLine(to: points[0])
        
        ttl -= 1
        if ttl == 0{completeLine()}
        
    }
    
    func completeLine(){
        if points == []{return}
        
        var allSame = false
        var b = [] as [Ball]
        for ball in parent.balls {
            if !ball.captured && shape.intersects(ball.shape){
                allSame = true
                b.append(ball)
                if ball.type != b[0].type{
                    allSame = false
                    break
                }
            }
        }
        if allSame {
            b.remove(at: Int.random(in:b.startIndex ..< b.endIndex))
            for ball in b{
                ball.capture()
            }
        }
        
        
        points.append(points[0])
        points = []
        path = CGMutablePath()
        shape.removeFromParent()
        shape2.removeFromParent()
    }
    
    func update()
    {
        shape.path = path
        shape2.path = closerPath
    }
    
}


class GameScene: SKScene, CanReceiveTransitionEvents {

    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    var balls = [] as [Ball]
    var lines = [Int:Line]()
    
    var held = 0
    var checkWin = false
    var state = 0
    var startTime = 0.0
    
    func changeState()
    {
        switch state {
        case 0:
            label?.text = ""
            createBalls()
            startTime = NSDate().timeIntervalSince1970
        case 1:
            UpdateHighscore()
            removeBalls()
            showHighscores()
        case 2:
            label?.text = "Press Any Pixel"
            state = -1
        default:
            break
        }
        state+=1

        
    }
    
    func showHighscores(){
        if let hs = getHighScore(){
            var t:String =  ("1:\t" + String(hs.a))
            t+="\n2:\t" + String(hs.b)
            t+="\n3:\t" + String(hs.c)
            t+="\n4:\t" + String(hs.d)
            t+="\n5:\t" + String(hs.e)
            label?.text = t
        }
        else
        {
            label?.text = "Unexpected Error"
        }
        
    }
    func UpdateHighscore(){
        let now = NSDate().timeIntervalSince1970
        let points = Int(((now-startTime)*1000).rounded())
        if var hs = getHighScore(){
            hs.f = points
            hs.Sort()
            storeHighScore(hs: hs )
        }
        else
        {
            var hs = Highscore(a:102746 ,b:119467,c:1847564,d:3498637467,e:209487589456,f:points)
            hs.Sort()
            storeHighScore(hs:hs)
        }
    }
    
    func removeBalls()
    {
        for ball in balls {
            ball.capture()
        }
        balls=[]
    }
    
    func createBalls()
    {
        for _ in 0..<10{
            for type in 0..<5 {
                let newBall = Ball(pos:CGPoint(
                        x:CGFloat.random(in: -self.size.width/2+20...self.size.width/2-20),
                        y:CGFloat.random(in: -self.size.height/2+20...self.size.height/2-20)
                    ),type:type,parent: self)
                        
                    balls.append(newBall)
                
            }
            
        }
        for ball in balls {
            addChild(ball.shape)
        }
        
    }
    
    override func didMove(to view: SKView) {
        //let hs = Highscore(a: 1, b: 2, c: 3, d:4, e: 7, f:4)
        //storeHighScore(hs: hs)
        removeHighScore()
        
        self.size = CGSize(width: 768, height: 1024)
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 1.0
            label.text = "Press Any Pixel"
        }
  
    }
    
    
    func touchDown(atPoint pos : CGPoint , hash:Int) {

        switch state {
        case 0:
            changeState()
        case 1:
            lines[hash] = Line(pos:pos,parent:self)
        case 2:
            changeState()
        default:
            return
        }
        

    }
    
    func touchMoved(toPoint pos : CGPoint, hash:Int) {

        lines[hash]?.addPoint(pos:pos)
    }
    
    func touchUp(atPoint pos : CGPoint , hash:Int) {
        
        lines[hash]?.completeLine()
        lines.removeValue(forKey: hash)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for t in touches { self.touchDown(atPoint: t.location(in: self),hash:t.hash) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self),hash:t.hash)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self),hash:t.hash) }

    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self),hash:t.hash) }
    }
    
    var i = CGFloat(0);

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        for ball in balls {
            ball.update()
        }
        for line in lines
        {
            line.value.update()
        }
        
        if checkWin{
            var n = [0,0,0,0,0]
            for ball in balls{
                if !ball.captured{
                    n[ball.type] += 1
                }
            }

            if n.min()==1{
                changeState()
            }
            checkWin = false
        }
        
        
    }
    
    func viewWillTransition(to size: CGSize) {
        self.size = size
        for ball in balls{
            let pos = ball.pos
            ball.pos.x = pos.y
            ball.pos.y = pos.x
            ball.shape.position = ball.pos
        }
    }
    
}
