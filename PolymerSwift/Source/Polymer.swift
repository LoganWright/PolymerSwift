//
//  PolymerSwift.swift
//  PolymerSwift
//
//  Created by Logan Wright on 5/29/15.
//  Copyright (c) 2015 LowriDevs. All rights reserved.
//

import Foundation
import Polymer
import Genome
import AFNetworking

// MARK: TypeAliases

public typealias ResponseTransformer = (response: AnyObject?) -> GenomeMappableRawType?
public typealias SlugValidityCheck = (slugValue: AnyObject?, slugPath: String?) -> Bool
public typealias SlugValueForPath = (slug: AnyObject?, slugPath: String?) -> AnyObject?

// MARK: Response

public enum Response<T : GenomeObject> {
    case Result([T])
    case Error(NSError)
}

// MARK: Operation Type

public enum OperationType {
    case Get
    case Post
    case Put
    case Patch
    case Delete
}

// MARK: Endpoint Descriptor

public class EndpointDescriptor {
    
    public final private(set) var currentOperation: OperationType = .Get
    
    // MARK: Required Properties
    
    public var baseUrl: String { fatalError("Must Override") }
    public var endpointUrl: String { fatalError("Must Override") }
    
    // MARK: Optional Properties
    
    public var responseKeyPath: String? { return nil }
    public var acceptableContentTypes: Set<String>? { return nil }
    public var headerFields: [String : AnyObject]? { return nil }
    public var requestSerializer: AFHTTPRequestSerializer? { return nil }
    public var responseSerializer: AFHTTPResponseSerializer? { return nil }
    public var shouldAppendHeaderToResponse: Bool { return false }
    
    // MARK: Response Transformer
    
    public var responseTransformer: ResponseTransformer? { return nil }
    
    // MARK: Slug Interaction
    
    public var slugValidityCheck: SlugValidityCheck? { return nil }
    public var slugValueForPath: SlugValueForPath? { return nil }
    
    // MARK: Initialization
    
    required public init() {}
}

// MARK: Endpoint

public class Endpoint<T,U where T : EndpointDescriptor, U : GenomeObject> {
    
    // MARK: TypeAliases
    
    public typealias ResponseBlock = (response: Response<U>) -> Void
    private typealias ObjCResponseBlock = (result: AnyObject?, error: NSError?) -> Void
    
    // MARK: Private Properties
    
    final let descriptor = T()
    
    final let slug: AnyObject?
    final let parameters: PLYParameterEncodableType?
    
    private final lazy var ep: BackingEndpoint! = BackingEndpoint(endpoint: self)
    
    // MARK: Initialization
    
    public convenience init() {
        self.init(slug: nil, parameters: nil)
    }
    
    public convenience init(slug: AnyObject?) {
        self.init(slug: slug, parameters: nil)
    }
    
    public convenience init(parameters: PLYParameterEncodableType?) {
        self.init(slug: nil, parameters: parameters)
    }
    
    required public init(slug: AnyObject?, parameters: PLYParameterEncodableType?) {
        self.slug = slug
        self.parameters = parameters
    }
    
    // MARK: Networking
    
    public func get(responseBlock: ResponseBlock) {
        descriptor.currentOperation = .Get
        let wrappedCompletion = objcResponseBlockForResponseBlock(responseBlock)
        ep.getWithCompletion(wrappedCompletion)
    }
    
    public func post(responseBlock: ResponseBlock) {
        descriptor.currentOperation = .Post
        let wrappedCompletion = objcResponseBlockForResponseBlock(responseBlock)
        ep.postWithCompletion(wrappedCompletion)
    }
    
    public func put(responseBlock: ResponseBlock) {
        descriptor.currentOperation = .Put
        let wrappedCompletion = objcResponseBlockForResponseBlock(responseBlock)
        ep.putWithCompletion(wrappedCompletion)
    }
    
    public func patch(responseBlock: ResponseBlock) {
        descriptor.currentOperation = .Patch
        let wrappedCompletion = objcResponseBlockForResponseBlock(responseBlock)
        ep.putWithCompletion(wrappedCompletion)
    }
    
    public func delete(responseBlock: ResponseBlock) {
        descriptor.currentOperation = .Delete
        let wrappedCompletion = objcResponseBlockForResponseBlock(responseBlock)
        ep.deleteWithCompletion(wrappedCompletion)
    }
    
    /*!
    Used to map the objc response to the swift response
    
    :param: completion the completion passed by the user to call with the Result
    */
    private func objcResponseBlockForResponseBlock(responseBlock: ResponseBlock) -> ObjCResponseBlock {
        return { (result, error) -> Void in
            let response: Response<U>
            if let _result = result as? [U] {
                response = .Result(_result)
            } else if let _result = result as? U {
                response = .Result([_result])
            } else if let _error = error {
                response = .Error(_error)
            } else {
                let err = NSError(message: "No Result: \(result) or Error: \(error).  Unknown.")
                response = .Error(err)
            }
            responseBlock(response: response)
        }
    }
}

// MARK: Error

private extension NSError {
    convenience init(code: Int = 1, message: String) {
        self.init(domain: "com.polymer.errordomain", code: 1, userInfo: [NSLocalizedDescriptionKey : message])
    }
}
