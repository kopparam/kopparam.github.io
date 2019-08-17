---
layout: post
title:  "Test Driven Development and static methods in Java"
date:   2019-08-17 02:07:36 +0000
categories: TDD
---

## The scenario

There were more than a lot of instances when Java's static methods get in the way of test driving my implementation. In this post, I want to explain what kind of situations these are, how I choose to solve them and why I need to solve them.

The most basic example for this situation is generating random UUIDs in the service layer. Let us take an example where I get a purchase order payload, which has information on how to process the payment and what to purchase with that money. The method signature looks something like this.

{% highlight java %}
CheckoutResponse checkout(Payment payment, Order order);
{% endhighlight %}

Now I need to generate a random UUID for the primary key of a `payment` and then also write this in the foreign key of `order`. So I write a test first for this. Ehhh wait, in Java the method to generate a random UUID is static.

{% highlight java %}
public static UUID randomUUID();
{% endhighlight %}

We have three options here:
1. Use PowerMock and mock that static method. Yuck! so fragile.
2. Write a simple wrapper class that calls the static method and use(mock) that.
3. Inject a `Supplier<UUID>` to the class under test and mock that.

I am not going to go through why I discarded the PowerMock option, if you must know, I just dont like it.

Let's think about that last option right there.

# Use a Supplier interface to inject some behavior

Cool! Java 8 some sick interfaces that help us do this.

So let me inject this into the class under test.

{% highlight java %}
public CheckoutProcessor(..., Supplier<UUID> randomUUID);
{% endhighlight %}

Now, this is how I can use it to stub the behavior using JUnit5

{% highlight java %}
class TestCheckoutProcessor {
  @Mock
  Supplier<UUID> randomUUID;
  
  @BeforeEach
  void setUp() {
    initMocks(this);
  }
  
  @Test
  void name() {
    CheckoutProcessor tt = new CheckoutProcessor(..., randomUUID);
    when(supplier.get()).thenReturn(UUID.randomUUID());
  
    tt.gimme();
  
    verify(supplier).get();
  }
}
{% endhighlight %}

Great! I can give it behavior and verify what it does just fine. Now let us see how it looks when we create a new wrapper class.

# Use a wrapper class which can be mocked

This involves adding a simple class which has very little to worry in life.

{% highlight java %}
public class UUIDSource {
  public UUID getRandom() {
    return UUID.randomUUID();
  }
}
{% endhighlight %}

And I don't think I want to repeat showing how it can be tested. It is simple the same as the Supplier way.

# Evaluating the options

Both the options seem compelling in their own right. But I think the Supplier option takes a hit on readability which makes me always choose the wrapper class.

Well let's think about how an application would bootstrap this class. Most Java applications would use a Dependency Injection framework like Spring or Guice. Or, some may initialize it in Main or a bootstrapper class.

Either ways, there will be a method or some piece of code that initializes the Checkout processor. In the two options that we have this would look a bit different.

With supplier, we can use a method reference to call the static method when `Supplier.get()` is called:
{% highlight java %}
new PaymentProcessor(..., UUID::randomUUID);
{% endhighlight %}

With the wrapper, we can simple make it:
{% highlight java %}
new PaymentProcessor(..., new UUIDSource());
{% endhighlight %}

Now, here is where I think the readability is bit compromised with the Supplier. If someone wants to know what or where this random UUID generator does or is, they would either `Go to declaration` in their IDE or checkout the documentation of the function there are using.

With the wrapper we can simple `Go to declaration`, since it is just a method. And we can also look up it's Java doc(at least once we write it ;) )

But, with the Supplier, the Java doc points to the Supplier's get method and we have to back-track the creation of classes and finally look it up in the Dependency framework or Main where it was initialized. 

I hope you found this useful and use these wrappers so that your implementation can be test driven.

Have a splendid day and keep hacking.
