import prisma from "../lib/prisma";

async function main() {
    const randomStr = Math.random().toString(36).substring(7);

    // Create a new user
    const user = await prisma.user.create({
        data: {
            name: "Alice",
            email: `alice-${randomStr}@prisma.io`,
        },
    });

    // Create a new post for that user
    await prisma.post.create({
        data: {
            title: "Hello World",
            content: "This is my first post!",
            published: true,
            authorId: user.id,
        }
    });
    console.log("Created user:", user);

    // Fetch all users with their posts
    const allUsers = await prisma.user.findMany({
        include: {
            posts: true,
        },
    });
    console.log("All users:", JSON.stringify(allUsers, null, 2));
}

main()
    .then(async () => {
        await prisma.$disconnect();
    })
    .catch(async (e) => {
        console.error(e);
        await prisma.$disconnect();
        process.exit(1);
    });