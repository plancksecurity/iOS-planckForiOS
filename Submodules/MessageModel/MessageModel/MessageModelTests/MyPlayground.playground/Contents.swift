//: Playground - noun: a place where people can play

import UIKit
import MessageModel

var str = "Hello, playground"

print(str)

let filtro1 = UnifiedFilter()
let filtro2 = FlaggedFilter()
let filtro3 = FilterBase()
let filtro4 = AccountFilter(address: "test")
let filtro5 = AccountFilter(address: "test@test.com")
let filtro6 = AccountFilter(address: "test@test.com")
let filtro7 = AccountFilter(address: "test@mail.com")
let filtro8 = AttachmentFilter()
let filtro9 = UnreadFilter()
let filtro10 = SearchFilter(subject: "test")
let filtro11 = SearchFilter(subject: "test")

let composite = CompositeFilter<FilterBase>()

composite.add(filter: filtro1)
composite.add(filter: filtro2)
composite.add(filter: filtro3)
composite.add(filter: filtro4)
composite.add(filter: filtro5)
composite.add(filter: filtro6)
composite.add(filter: filtro7)
composite.add(filter: filtro8)
composite.add(filter: filtro9)
composite.add(filter: filtro10)
composite.add(filter: filtro11)

print(composite.title)

print(composite.predicates)

print(filtro4 == filtro5)
print(filtro5 == filtro6)
print(filtro5 == filtro7)
print(filtro10 == filtro11)
print(filtro4 == filtro10)
print(filtro3 == filtro2)
