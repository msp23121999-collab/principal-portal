import { AuthRepository } from '../repositories/auth.repository';
import { generateToken } from '../utils/jwt';

export class AuthService {
  static async login(email: string) {
    if (!email) throw new Error('Email is required');
    const user = await AuthRepository.findUserByEmail(email);
    if (!user) {
      throw new Error('Invalid credentials or user not found');
    }
    const token = generateToken({
      id: user.id,
      email: user.email,
      role: user.role,
      department_id: user.department_id,
    });
    return { token, user };
  }
}
