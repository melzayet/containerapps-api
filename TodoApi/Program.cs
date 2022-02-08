using Dapr.Actors;
using Dapr.Actors.Client;
using Microsoft.EntityFrameworkCore;
using MyActor.Interfaces;
using MyActorService;
using Dapr.Client;

//wait for Dapr service init
using var client = new DaprClientBuilder().Build();
await client.CheckHealthAsync();

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<TodoDb>(opt => opt.UseInMemoryDatabase("TodoList"));
builder.Services.AddDatabaseDeveloperPageExceptionFilter();

builder.Services.AddActors(options =>
{
    // Register actor types and configure actor settings
    options.Actors.RegisterActor<TaskActor>();
});
        
var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
    app.UseHttpsRedirection();
        

app.UseRouting();

app.UseEndpoints(endpoints =>
{
    // Register actors handlers that interface with the Dapr runtime.
    endpoints.MapActorsHandlers();
});
           
app.MapGet("/", () => "Please call /todoitems");

app.MapGet("/todoitems", async (TodoDb db) =>
    await db.Todos.ToListAsync());

app.MapGet("/todoitems/complete", async (TodoDb db) =>
    await db.Todos.Where(t => t.IsComplete).ToListAsync());

app.MapGet("/todoitems/actors/{id}", async (string id, TodoDb db) => {
    var actorType = "TaskActor";
    // An ActorId uniquely identifies an actor instance
    // If the actor matching this id does not exist, it will be created
    var actorId = new ActorId(id);

    
    // Create the local proxy by using the same interface that the service implements.    
    var proxy = ActorProxy.Create<IMyActor>(actorId, actorType);

    TaskData data = await proxy.GetDataAsync();
    if(data != null)
    {
        Results.Ok(data);
    }
    else
        Results.NotFound();

});

app.MapGet("/todoitems/{id}", async (int id, TodoDb db) => {
    if (await db.Todos.FindAsync(id) is Todo todo){        
        Results.Ok(todo);
    }
    Results.NotFound();            
});

app.MapPost("/todoitems", async (Todo todo, TodoDb db) =>
{
    db.Todos.Add(todo);        
    await db.SaveChangesAsync();

    var actorType = "TaskActor";

    // An ActorId uniquely identifies an actor instance
    // If the actor matching this id does not exist, it will be created
    var actorId = new ActorId(todo.Owner);

    // Create the local proxy by using the same interface that the service implements.    
    var proxy = ActorProxy.Create<IMyActor>(actorId, actorType);

    // Now you can use the actor interface to call the actor's methods.
    
    await proxy.SetDataAsync(todo.Id.ToString());

    return Results.Created($"/todoitems/{todo.Id}", todo);
});

app.MapPut("/todoitems/{id}", async (int id, Todo inputTodo, TodoDb db) =>
{
    var todo = await db.Todos.FindAsync(id);

    if (todo is null) return Results.NotFound();

    todo.Name = inputTodo.Name;
    todo.IsComplete = inputTodo.IsComplete;
    todo.Owner = inputTodo.Owner;

    await db.SaveChangesAsync();

    return Results.NoContent();
});

app.MapDelete("/todoitems/{id}", async (int id, TodoDb db) =>
{
    if (await db.Todos.FindAsync(id) is Todo todo)
    {
        db.Todos.Remove(todo);
        await db.SaveChangesAsync();
        return Results.Ok(todo);
    }

    return Results.NotFound();
});

app.Run();

class Todo
{
    public int Id { get; set; }
    public string? Name { get; set; }
    public string? Owner { get; set; }
    public bool IsComplete { get; set; }
}

class TodoDb : DbContext
{
    public TodoDb(DbContextOptions<TodoDb> options)
        : base(options) { }

    public DbSet<Todo> Todos => Set<Todo>();
}


