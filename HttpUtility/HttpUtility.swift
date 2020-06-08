//
//  HttpUtility.swift
//  HttpUtility
//
//  Created by CodeCat15 on 5/17/20.
//  Copyright © 2020 CodeCat15. All rights reserved.
//

import Foundation

public struct HUNetworkError : Error
{
    let reason: String?
    let httpStatusCode: Int?
}

public enum HUHttpMethods : String
{
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}


public struct HttpUtility
{
    private var _token: String? = nil
    private var _customJsonDecoder: JSONDecoder? = nil
    
   public init(token: String?){
        _token = token
    }

    public init(token: String?, decoder: JSONDecoder?){
        _token = token
        _customJsonDecoder = decoder
    }

    public init(WithJsonDecoder decoder: JSONDecoder){
        _customJsonDecoder = decoder
    }
    
    public init(){}
    
    public func request<T:Decodable>(requestUrl: URL, method: HUHttpMethods, requestBody: Data? = nil,  resultType: T.Type, completionHandler:@escaping(Result<T?, HUNetworkError>)-> Void)
    {
        switch method
        {
        case .get:
            getData(requestUrl: requestUrl, resultType: resultType) { completionHandler($0)}
            break

        case .post:
            postData(requestUrl: requestUrl, requestBody: requestBody!, resultType: T.self) { completionHandler($0)}
            break

        case .put:
            putData(requestUrl: requestUrl, resultType: resultType) { completionHandler($0)}
            break

        case .delete:
            deleteData(requestUrl: requestUrl, resultType: resultType) { completionHandler($0)}
            break
        }
    }

    // MARK: - Private functions
    private func createJsonDecoder() -> JSONDecoder
    {
        let decoder =  _customJsonDecoder != nil ? _customJsonDecoder! : JSONDecoder()
        if(_customJsonDecoder == nil)
        {
            decoder.dateDecodingStrategy = .iso8601
        }
        return decoder
    }
    
    private func createUrlRequest(requestUrl: URL) -> URLRequest
    {
        var urlRequest = URLRequest(url: requestUrl)
        if(_token != nil)
        {
            urlRequest.addValue(_token!, forHTTPHeaderField: "authorization")
        }
        
        return urlRequest
    }

    private func decodeJsonResponse<T: Decodable>(data: Data, responseType: T.Type) -> T?
    {
        let decoder = self.createJsonDecoder()
        do{
            return try decoder.decode(responseType, from: data)
        }catch let error{
            debugPrint("deocding error =>\(error)")
        }
        return nil
    }

    private func performOperation<T: Decodable>(requestUrl: URLRequest, responseType: T.Type, completionHandler:@escaping(Result<T?, HUNetworkError>) -> Void)
    {
        URLSession.shared.dataTask(with: requestUrl) { (data, httpUrlResponse, error) in

            let statusCode = (httpUrlResponse as? HTTPURLResponse)?.statusCode
            if(error == nil && data != nil && data?.count != 0)
            {
                let response = self.decodeJsonResponse(data: data!, responseType: responseType)

                if(response != nil){
                    completionHandler(.success(response))
                }else{
                    completionHandler(.failure(HUNetworkError(reason: "decoding error", httpStatusCode: statusCode)))
                }
            }
            else
            {
                let networkError = HUNetworkError(reason: error.debugDescription,httpStatusCode: statusCode)
                completionHandler(.failure(networkError))
            }

        }.resume()
    }

    // MARK: - GET Api
    private func getData<T:Decodable>(requestUrl: URL, resultType: T.Type, completionHandler:@escaping(Result<T?, HUNetworkError>)-> Void)
    {
        var urlRequest = createUrlRequest(requestUrl: requestUrl)
        urlRequest.httpMethod = "get"

        performOperation(requestUrl: urlRequest, responseType: T.self) { (result) in
            completionHandler(result)
        }
    }

    // MARK: - POST Api
    private func postData<T:Decodable>(requestUrl: URL, requestBody: Data, resultType: T.Type, completionHandler:@escaping(Result<T?, HUNetworkError>)-> Void)
    {
        var urlRequest = createUrlRequest(requestUrl: requestUrl)
        urlRequest.httpMethod = "post"
        urlRequest.httpBody = requestBody
        urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")

        performOperation(requestUrl: urlRequest, responseType: T.self) { (result) in
            completionHandler(result)
        }
    }

    // MARK: - PUT Api
    private func putData<T:Decodable>(requestUrl: URL, resultType: T.Type, completionHandler:@escaping(Result<T?, HUNetworkError>)-> Void)
    {
        var urlRequest = createUrlRequest(requestUrl: requestUrl)
        urlRequest.httpMethod = "put"

        performOperation(requestUrl: urlRequest, responseType: T.self) { (result) in
            completionHandler(result)
        }
    }

    // MARK: - DELETE Api
    private func deleteData<T:Decodable>(requestUrl: URL, resultType: T.Type, completionHandler:@escaping(Result<T?, HUNetworkError>)-> Void)
    {
        var urlRequest = createUrlRequest(requestUrl: requestUrl)
        urlRequest.httpMethod = "delete"

        performOperation(requestUrl: urlRequest, responseType: T.self) { (result) in
            completionHandler(result)
        }
    }
}
