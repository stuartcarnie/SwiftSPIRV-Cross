//
//  main.swift
//  testcli
//
//  Created by Stuart Carnie on 18/1/21.
//

import Foundation
import GLSlang
import SPIRVCross
import SPIRVTools

@main
struct Test {
    static func main() throws {
        let stage = GLStage.vertex
        let code  = #"""
         #version 450
         #extension GL_GOOGLE_include_directive : enable

         layout(location = 0) out vec4 FragColor;

         void main()
         {
             int a = 3;
             a += 5;
             if (false)
                 FragColor = vec4(1, 2, 3, 4);
             a = 6;
             FragColor = vec4(1, 0, 0, a);
         }
        """#
        let vertShader = GLShader(source: code, stage: stage)
        
        do {
            try vertShader.parse(messages: [.vulkanRules, .spvRules])
        } catch GLShader.ShaderError.preprocess {
            print("Preprocess error")
            print(vertShader.infoLog)
            print(vertShader.debugLog)
            exit(1)
        } catch GLShader.ShaderError.parse {
            print("Parse error")
            print(vertShader.infoLog)
            print(vertShader.debugLog)
            exit(1)
        }
        
        let prog = GLProgram()
        prog.add(shader: vertShader)
        let vertSpv: Data
        do {
            try prog.link()
            let vertSpv1 = try prog.generate(stage: stage)
            let opt = SPVTOptimizer(environment: .universal1_5)
//            opt.registerDeadBranchElimPass()
//            opt.registerStaticSingleAssignmentRewritePass();
//            opt.registerAggressiveDeadCodeEliminationPass()
            vertSpv = opt.optimize(spirv: vertSpv1)!
        } catch GLProgram.ProgramError.link {
            print("Link error")
            print(prog.infoLog)
            exit(1)
        } catch GLProgram.ProgramError.noStage {
            print("No stage")
            exit(1)
        }
        
        let ctx = SPVContext()
        
        do {
            let vertMtl = try ctx.makeMetalCompiler(ir: try ctx.parse(data: vertSpv))
            var opt = vertMtl.makeOptions()
            opt.swizzleTextureSamples = false
            opt.forceNativeArrays = false
            opt.version = .version2_1
            let src = try vertMtl.compile(options: opt)
            print(src)
        }
    }
}
